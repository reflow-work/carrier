defmodule Carrier.Billing do
  use Carrier.Payments
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
           end_on = Plan.calc_end_on(plan, start_on, 1),
           {:ok, %Subscription{} = subscription} <-
             create_subscription(%{
               org_id: org_id,
               plan_id: plan_id,
               start_on: start_on,
               end_on: end_on
             }) do
        {:ok, subscription}
      end
    end)
  end

  # TODO: implement it
  # TODO: use the same time for expire and activate
  def activate_subscription(subscription_id) do
    with {:ok, %Subscription{status: :pending} = subscription} <-
           fetch_subscription(subscription_id),
         :ok <- expire_prev_subscription(subscription),
         {:ok, maybe_payment} <- pay_subscription(subscription),
         {:ok, %Subscription{} = activated_subscription} <-
           Subscription.activate(subscription, %{payment_id: maybe_payment[:id]}),
         {:ok, maybe_next_subscription} <- create_next_subscription(subscription) do
      {:ok, activated_subscription}
    end
  end

  # TODO: implement it
  defp fetch_subscription(subscription_id) do
    {:ok, %Subscription{id: subscription_id}}
  end

  defp had_subscription?() do
    Subscription.list_include_deleted()
    |> TenantRepo.exists?()
  end

  defp create_trial_subscription_if_first_time(%{org_id: org_id, start_on: start_on}) do
    with {:had_subscribable, false} <- {:had_subscribable, had_subscription?()},
         %Plan{type: :trial} = plan <- Super.fetch_trial_plan!(),
         end_on = Plan.calc_end_on(plan, start_on, 1),
         {:ok, %Subscription{} = trial_subscription} <-
           Subscription.create(%{
             org_id: org_id,
             plan_id: plan.id,
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

  # TODO: implement it
  defp create_next_subscription(%Subscription{}) do
    {:ok, %Subscription{}}
  end

  # TODO: implement it
  # TODO: refund?
  defp expire_prev_subscription(%Subscription{prev_subscription_id: prev_subscription_id})
       when not is_nil(prev_subscription_id) do
    with {:ok, %Subscription{} = prev_subscription} <- fetch_subscription(prev_subscription_id),
         {:ok, %Subscription{}} <- do_expire_subscription(prev_subscription_id) do
      :ok
    end
  end

  defp expire_subscription(%Subscription{prev_subscription_id: nil}) do
    :ok
  end

  # TODO: implement it
  defp do_expire_subscription(%Subscription{status: :active} = subscription) do
    with {:ok, %Subscription{} = expired_subscription} <- Subscription.expire(subscription) do
      {:ok, expired_subscription}
    end
  end

  defp do_expire_subscription(%Subscription{status: :expired} = subscription) do
    Logger.warn("Subscription #{subscription.id} is already expired")

    {:ok, subscription}
  end

  defp pay_subscription(%Subscription{}) do
    {:ok, %Payment{}}
  end

  defp recalc_start_on(%Subscription{end_on: end_on}, _start_on), do: end_on
  defp recalc_start_on(nil, start_on), do: start_on
end
