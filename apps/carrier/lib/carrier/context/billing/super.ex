defmodule Carrier.Billing.Super do
  use Carrier.Billing
  alias Carrier.TenantRepo

  def list_subscribable_plans() do
    Plan.list_subscribable()
    |> TenantRepo.all(skip_org_id: true)
    |> then(&{:ok, &1})
  end
end
