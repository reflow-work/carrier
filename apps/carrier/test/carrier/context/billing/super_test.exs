defmodule Carrier.Billing.SuperTest do
  use Carrier.DataCase, async: true
  use Carrier.Billing

  @moduletag repo: TenantRepo

  describe "list_subscribable/0" do
    setup do
      plan1 = TenantFactory.insert(:plan, type: :trial)
      plan2 = TenantFactory.insert(:plan, type: :basic)
      plan3 = TenantFactory.insert(:plan, type: :pro)
      TenantFactory.insert(:plan, type: :pro, status: :deleted)

      %{plans: [plan1, plan2, plan3]}
    end

    test "with valid params", %{plans: [_, plan2, plan3]} do
      assert {:ok, [fetched_plan1, fetched_plan2]} = Billing.Super.list_subscribable_plans()

      assert same_records?(fetched_plan1, plan2)
      assert same_records?(fetched_plan2, plan3)
    end
  end
end
