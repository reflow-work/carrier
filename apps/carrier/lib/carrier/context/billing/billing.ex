defmodule Carrier.Billing do
  use Carrier.{Payments, Accounts, Setting}
  require Logger
  alias Carrier.Billing.{Plan, Subscription}
  alias Carrier.Billing.Super
  alias Carrier.Works
  alias Carrier.TenantRepo
  alias Carrier.Core.Nillable

  defmacro __using__([]) do
    quote do
      alias Carrier.Billing
      alias Carrier.Billing.{Plan, Subscription}
    end
  end

  def start_subscription(%{org_id: org_id, plan_id: plan_id, start_on: start_on} = params) do
    maybe_end_on = params[:end_on]

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Plan{} = plan} <- Super.fetch_plan(plan_id),
           # TODO: expire active subscription?
           maybe_active_subscription <- get_active_subscription(),
           start_on = recalc_start_on(maybe_active_subscription, start_on),
           end_on = maybe_end_on || Plan.calc_end_on(plan, start_on, 0),
           {:ok, %Subscription{} = subscription} <-
             create_subscription(%{
               org_id: org_id,
               plan_id: plan_id,
               extension_count: 0,
               start_on: start_on,
               end_on: end_on
             }),
           {:ok, subscription} <-
             if(maybe_active_subscription,
               do: {:ok, subscription},
               else: activate_subscription(subscription)
             ) do
        {:ok, subscription}
      end
    end)
  end

  def create_subscription(%{org_id: org_id, plan_id: plan_id} = params) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Plan{subscribable: subscribable, price: price, currency: currency}} <-
             Super.fetch_plan(plan_id),
           {:ok, maybe_payment} <-
             if(subscribable,
               do: Payments.create_payment(%{org_id: org_id, amount: price, currency: currency}),
               else: {:ok, nil}
             ),
           {:ok, %Subscription{} = subscription} <-
             Subscription.create(
               params
               |> Map.put(:payment_id, maybe_payment |> Nillable.map(& &1.id))
             )
             |> TenantRepo.insert() do
        {:ok, subscription}
      end
    end)
  end

  def activate_subscription(%Subscription{status: :pending} = pending_subscription) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, _maybe_payment} <- pay_subscription(pending_subscription),
           {:ok, %Subscription{} = activated_subscription} <-
             Subscription.activate(pending_subscription, %{activated_at: DateTime.utc_now()})
             |> TenantRepo.update(),
           {:ok, _} <- create_subscription_expiring_job(activated_subscription),
           {:ok, _} <- create_next_subscription(activated_subscription) do
        {:ok, activated_subscription}
      end
    end)
  end

  def expire_subscription(subscription_id) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, active_subscription} <- fetch_subscription_with_state(subscription_id, :active),
           {:ok, expired_subscription} <-
             do_expire_subscription(active_subscription),
           maybe_pending_subscription = get_pending_subscription(),
           {:ok, _} <-
             if(maybe_pending_subscription,
               do: activate_subscription(maybe_pending_subscription),
               else: {:ok, nil}
             ) do
        {:ok, expired_subscription}
      else
        {
          :error,
          {:resource_not_found, %{target: Subscription, conditions: %{state: :active}}}
        } ->
          {:error, :subscription_to_expire_not_exist}

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  def fetch_subscription(subscription_id) do
    Subscription.fetch(subscription_id)
    |> Subscription.preload_payment()
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        subscription_with_plan = subscription |> Super.postload_plan()

        {:ok, subscription_with_plan}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: Subscription, conditions: %{subscription_id: subscription_id}}}}
    end
  end

  def fetch_active_subscription() do
    Subscription.fetch_active()
    |> Subscription.preload_payment()
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        subscription_with_plan = subscription |> Super.postload_plan()

        {:ok, subscription_with_plan}

      nil ->
        {:error, {:resource_not_found, %{target: Subscription, conditions: %{state: :active}}}}
    end
  end

  def fetch_pending_subscription() do
    Subscription.fetch_pending()
    |> Subscription.preload_payment()
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        subscription_with_plan = subscription |> Super.postload_plan()

        {:ok, subscription_with_plan}

      nil ->
        {:error, {:resource_not_found, %{target: Subscription, conditions: %{state: :active}}}}
    end
  end

  def get_active_trial_subscription() do
    Subscription.fetch_active_trial()
    |> TenantRepo.one()
  end

  def have_active_subscription?() do
    Subscription.fetch_active()
    |> TenantRepo.exists?()
  end

  def have_active_non_trial_subscription?() do
    Subscription.fetch_active_non_trial()
    |> TenantRepo.exists?()
  end

  defp fetch_subscription_with_state(subscription_id, state) do
    Subscription.fetch_with_state(subscription_id, state)
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        {:ok, subscription}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: Subscription, conditions: %{subscription_id: subscription_id, state: state}}}}
    end
  end

  defp get_pending_subscription() do
    Subscription.fetch_pending()
    |> TenantRepo.one()
  end

  defp get_active_subscription() do
    Subscription.fetch_active()
    |> TenantRepo.one()
  end

  defp create_subscription_expiring_job(%Subscription{
         id: subscription_id,
         org_id: org_id,
         end_on: end_on
       }) do
    with {:ok, subscription_expiring_job} <-
           %{org_id: org_id, subscription_id: subscription_id}
           |> Works.SubscriptionExpiringJob.new(
             scheduled_at: end_on,
             meta: %{org_id: org_id}
           )
           |> TenantRepo.insert() do
      {:ok, subscription_expiring_job}
    end
    |> tap(fn _ ->
      Logger.debug(
        "next SubscriptionExpiringJob of subscription_id: #{subscription_id} is scheduled_at #{inspect(end_on)}"
      )
    end)
  end

  defp create_next_subscription(
         %Subscription{org_id: org_id, plan_id: plan_id, extension_count: extension_count} =
           subscription
       ) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Plan{subscribable: true} = plan} <- Super.fetch_plan(plan_id),
           %{
             origin_subscription_id: origin_subscription_id
           } = Subscription.get_info_for_next_subscription(subscription),
           {:ok, %Subscription{} = origin_subscription} <-
             fetch_subscription(origin_subscription_id),
           new_extension_count = extension_count + 1,
           start_on = Plan.calc_start_on(plan, origin_subscription.start_on, new_extension_count),
           end_on = Plan.calc_end_on(plan, origin_subscription.start_on, new_extension_count),
           {:ok, %Subscription{} = pending_subscription} <-
             create_subscription(%{
               org_id: org_id,
               plan_id: plan_id,
               origin_subscription_id: origin_subscription_id,
               extension_count: new_extension_count,
               start_on: start_on,
               end_on: end_on
             }) do
        {:ok, pending_subscription}
      else
        {:ok, %Plan{subscribable: false}} -> {:ok, nil}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp do_expire_subscription(%Subscription{status: :active} = subscription) do
    with {:ok, %Subscription{} = expired_subscription} <-
           Subscription.expire(subscription, %{expired_at: DateTime.utc_now()})
           |> TenantRepo.update() do
      {:ok, expired_subscription}
    end
  end

  defp do_expire_subscription(%Subscription{status: :expired} = subscription) do
    Logger.warning("Subscription #{subscription.id} is already expired")

    {:ok, subscription}
  end

  defp pay_subscription(
         %Subscription{
           org_id: org_id,
           plan_id: plan_id,
           payment_id: payment_id
         } = subscription
       )
       when not is_nil(payment_id) do
    with {:ok, %Plan{subscribable: true, price: price, currency: currency} = plan} <-
           Super.fetch_plan(plan_id),
         {:ok, %User{org: %Org{name: billing_name}, email: billing_email}} <-
           Accounts.fetch_billing_user(),
         {:ok, %Payment{} = payment} <-
           Payments.process_payment(payment_id, %{
             org_id: org_id,
             amount: price,
             currency: currency,
             order_id: Subscription.calc_unique_key(subscription),
             order_name: "reflow #{Plan.get_full_name(plan)}",
             customer_email: billing_email,
             customer_name: billing_name
           }) do
      {:ok, payment}
    else
      {:ok, %Plan{subscribable: false}} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  defp pay_subscription(%Subscription{payment_id: nil}) do
    {:ok, nil}
  end

  defp recalc_start_on(%Subscription{end_on: end_on}, _start_on), do: end_on
  defp recalc_start_on(nil, start_on), do: start_on
end
