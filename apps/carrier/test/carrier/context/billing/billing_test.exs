defmodule Carrier.BillingTest do
  use Carrier.DataCase, async: true
  use Carrier.Billing
  use Oban.Testing, repo: Carrier.Repo
  alias Carrier.Factory
  alias Carrier.Repo

  @moduletag repo: Repo

  describe "list_subscribable/0" do
    setup do
      plan1 = Factory.insert(:plan, type: :trial)
      plan2 = Factory.insert(:plan, type: :basic)
      plan3 = Factory.insert(:plan, type: :pro)

      %{plans: [plan1, plan2, plan3]}
    end

    test "with valid params", %{plans: [_, plan2, plan3]} do
      assert {:ok, [fetched_plan1, fetched_plan2]} = Billing.list_subscribable_plans()

      assert same_records?(fetched_plan1, plan2)
      assert same_records?(fetched_plan2, plan3)
    end
  end
end
