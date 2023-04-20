defmodule Carrier.Billing.Super do
  use Carrier.Billing
  alias Carrier.TenantRepo

  def list_subscribable_plans() do
    Plan.list_subscribable()
    |> TenantRepo.all(skip_org_id: true)
    |> then(&{:ok, &1})
  end

  def fetch_plan(plan_id) do
    Plan.fetch(plan_id)
    |> TenantRepo.one(skip_org_id: true)
    |> case do
      %Plan{} = plan ->
        {:ok, plan}

      nil ->
        {:error, {:resource_not_found, %{target: Plan, conditions: %{plan_id: plan_id}}}}
    end
  end

  def fetch_trial_plan!() do
    Plan.fetch_trial()
    |> TenantRepo.one(skip_org_id: true)
  end

  def postload_plan(%Subscription{} = subscription) do
    subscription
    |> TenantRepo.preload(:plan, skip_org_id: true)
  end
end
