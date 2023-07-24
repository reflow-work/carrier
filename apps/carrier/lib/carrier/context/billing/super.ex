defmodule Carrier.Billing.Super do
  use Carrier.Billing
  alias Carrier.Repo

  def list_subscribable_plans() do
    Plan.list_subscribable()
    |> Repo.all(org_id: :skip)
    |> then(&{:ok, &1})
  end

  def fetch_plan(plan_id) do
    Plan.fetch(plan_id)
    |> Repo.one(org_id: :skip)
    |> case do
      %Plan{} = plan ->
        {:ok, plan}

      nil ->
        {:error, {:resource_not_found, %{target: Plan, conditions: %{plan_id: plan_id}}}}
    end
  end

  def fetch_trial_plan!() do
    Plan.fetch_trial()
    |> Repo.one(org_id: :skip)
  end

  def postload_plan(%Subscription{} = subscription) do
    subscription
    |> Repo.preload([plan: :role], org_id: :skip)
  end

  def postload_role(%Plan{} = plan) do
    plan
    |> Repo.preload(:role, org_id: :skip)
  end
end
