defmodule Carrier.Billing do
  use Carrier.{Payments, Accounts}
  require Logger
  alias Carrier.Billing.{Plan, Subscription}
  alias Carrier.Billing.Super
  alias Carrier.Works
  alias Carrier.TenantRepo

  defmacro __using__([]) do
    quote do
      alias Carrier.Billing
      alias Carrier.Billing.{Plan, Subscription}
    end
  end

  def start_subscription(%{org_id: org_id, plan_id: plan_id, start_on: start_on}) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Plan{} = plan} <- Super.fetch_plan(plan_id),
           :ok <- Plan.check_subscribable(plan),
           {:ok, maybe_trial_subscription} <-
             create_trial_subscription_if_first_time(%{org_id: org_id, start_on: start_on}),
           start_on = recalc_start_on(maybe_trial_subscription, start_on),
           end_on = Plan.calc_end_on(plan, start_on, 0),
           {:ok, %Subscription{} = subscription} <-
             create_subscription(%{
               org_id: org_id,
               plan_id: plan_id,
               extension_count: 0,
               start_on: start_on,
               end_on: end_on
             }) do
        {:ok, subscription}
      end
    end)
  end

  # TODO: use the same time for expire and activate
  def activate_subscription(subscription_id) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Subscription{status: :pending} = pending_subscription} <-
             fetch_subscription_with_state(subscription_id, :pending),
           {:ok, _} <- expire_active_subscription(),
           {:ok, %Payment{} = payment} <- pay_subscription(pending_subscription),
           {:ok, %Subscription{} = activated_subscription} <-
             Subscription.activate(pending_subscription, %{
               payment_id: payment.id,
               activated_at: DateTime.utc_now()
             })
             |> TenantRepo.update(),
           {:ok, _maybe_next_subscription} <- create_next_subscription(activated_subscription) do
        {:ok, activated_subscription}
      else
        {:error, {:resource_not_found, %{target: Subscription, conditions: %{state: :pending}}}} ->
          {:error, :subscription_can_not_be_activated}
      end
    end)
  end

  def fetch_active_subscription() do
    Subscription.fetch_active()
    |> Subscription.preload_payment()
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        subscription_with_plan =
          subscription
          |> TenantRepo.preload([:plan], skip_org_id: true)

        {:ok, subscription_with_plan}

      nil ->
        {:error, {:resource_not_found, %{target: Subscription, conditions: %{state: :active}}}}
    end
  end

  def have_active_subscription?() do
    Subscription.fetch_active()
    |> TenantRepo.exists?()
  end

  defp fetch_subscription(subscription_id) do
    Subscription.fetch(subscription_id)
    |> TenantRepo.one()
    |> case do
      %Subscription{} = subscription ->
        {:ok, subscription}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: Subscription, conditions: %{subscription_id: subscription_id}}}}
    end
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

  defp had_subscription?() do
    Subscription.list_include_deleted()
    |> TenantRepo.exists?()
  end

  defp create_trial_subscription_if_first_time(%{org_id: org_id, start_on: start_on}) do
    with {:had_subscribable, false} <- {:had_subscribable, had_subscription?()},
         %Plan{type: :trial} = plan <- Super.fetch_trial_plan!(),
         end_on = Plan.calc_end_on(plan, start_on, 0),
         {:ok, %Subscription{} = trial_subscription} <-
           Subscription.create(%{
             org_id: org_id,
             plan_id: plan.id,
             extension_count: 0,
             start_on: start_on,
             end_on: end_on
           })
           |> TenantRepo.insert(),
         {:ok, %Subscription{} = activated_trial_subscription} <-
           trial_subscription
           |> Subscription.activate(%{activated_at: start_on})
           |> TenantRepo.update() do
      {:ok, activated_trial_subscription}
    else
      {:had_subscribable, true} -> {:ok, nil}
    end
  end

  # for only subscribable plans
  defp create_subscription(params) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Subscription{} = subscription} <-
             Subscription.create(params) |> TenantRepo.insert(),
           {:ok, _} <- create_subscription_activating_job(subscription) do
        {:ok, subscription}
      end
    end)
  end

  defp create_subscription_activating_job(%Subscription{
         id: subscription_id,
         org_id: org_id,
         start_on: start_on
       }) do
    with {:ok, subscription_activating_job} <-
           %{org_id: org_id, subscription_id: subscription_id}
           |> Works.SubscriptionActivatingJob.new(
             scheduled_at: start_on,
             meta: %{org_id: org_id}
           )
           |> TenantRepo.insert() do
      {:ok, subscription_activating_job}
    end
    |> tap(fn _ ->
      Logger.debug(
        "next SubscriptionActivatingJob of subscription_id: #{subscription_id} is scheduled_at #{inspect(start_on)}"
      )
    end)
  end

  defp create_next_subscription(
         %Subscription{org_id: org_id, plan_id: plan_id, extension_count: extension_count} =
           subscription
       ) do
    TenantRepo.wrap_transaction(fn ->
      new_extension_count = extension_count + 1

      with {:ok, %Plan{} = plan} <- Super.fetch_plan(plan_id),
           %{
             origin_subscription_id: origin_subscription_id
           } = Subscription.get_info_for_next_subscription(subscription),
           {:ok, %Subscription{} = origin_subscription} <-
             fetch_subscription(origin_subscription_id),
           start_on = Plan.calc_start_on(plan, origin_subscription.start_on, new_extension_count),
           end_on = Plan.calc_end_on(plan, origin_subscription.start_on, new_extension_count),
           {:ok, %Subscription{} = subscription} <-
             create_subscription(%{
               org_id: org_id,
               plan_id: plan_id,
               origin_subscription_id: origin_subscription_id,
               extension_count: new_extension_count,
               start_on: start_on,
               end_on: end_on
             }) do
        {:ok, subscription}
      end
    end)
  end

  # TODO: refund?
  defp expire_active_subscription() do
    with {:ok, %Subscription{} = active_subscription} <- fetch_active_subscription(),
         {:ok, %Subscription{} = expired_subscription} <-
           expire_subscription(active_subscription) do
      {:ok, expired_subscription}
    else
      {:error, {:resource_not_found, %{target: Subscription, conditions: %{state: :active}}}} ->
        {:ok, nil}
    end
  end

  defp expire_subscription(%Subscription{status: :active} = subscription) do
    with {:ok, %Subscription{} = expired_subscription} <-
           Subscription.expire(subscription, %{expired_at: DateTime.utc_now()})
           |> TenantRepo.update() do
      {:ok, expired_subscription}
    end
  end

  defp expire_subscription(%Subscription{status: :expired} = subscription) do
    Logger.warn("Subscription #{subscription.id} is already expired")

    {:ok, subscription}
  end

  # Assumption: plan is always subscribable
  defp pay_subscription(%Subscription{
         org_id: org_id,
         plan_id: plan_id
       }) do
    with {:ok, %Plan{price: price, currency: currency} = plan} <-
           Super.fetch_plan(plan_id),
         {:ok, %User{org: %Org{name: billing_name}, email: billing_email}} <-
           Accounts.fetch_billing_user(),
         {:ok, %Payment{} = payment} <-
           Payments.process_payment(%{
             org_id: org_id,
             amount: price,
             currency: currency,
             order_name: Plan.get_full_name(plan),
             customer_email: billing_email,
             customer_name: billing_name
           }) do
      {:ok, payment}
    end
  end

  defp recalc_start_on(%Subscription{end_on: end_on}, _start_on), do: end_on
  defp recalc_start_on(nil, start_on), do: start_on
end
