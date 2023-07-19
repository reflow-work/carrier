defmodule Carrier.Billing.SuperTest do
  use Carrier.DataCase, async: true
  use Carrier.Billing

  @moduletag repo: TenantRepo

  describe "list_subscribable/0" do
    setup do
      plan1 = TenantFactory.insert(:plan, type: :trial)
      plan2 = TenantFactory.insert(:plan, type: :paid)
      plan3 = TenantFactory.insert(:plan, type: :paid)
      TenantFactory.insert(:plan, type: :paid, status: :deleted)

      %{plans: [plan1, plan2, plan3]}
    end

    test "with valid params", %{plans: [_, plan2, plan3]} do
      assert {:ok, [fetched_plan1, fetched_plan2]} = Billing.Super.list_subscribable_plans()

      assert same_records?(fetched_plan1, plan2)
      assert same_records?(fetched_plan2, plan3)
    end
  end

  describe "fetch_plan/1" do
    setup do
      plan = TenantFactory.insert(:plan)

      %{plan: plan}
    end

    test "with valid params", %{plan: plan} do
      assert {:ok, %Plan{} = fetched_plan} = Billing.Super.fetch_plan(plan.id)
      assert same_records?(fetched_plan, plan)
    end

    test "with invalid plan_id" do
      assert {:error, {:resource_not_found, %{target: Plan}}} = Billing.Super.fetch_plan(0)
    end

    test "with deleted_ plan_id", %{plan: plan} do
      plan |> soft_delete!()

      assert {:error, {:resource_not_found, %{target: Plan}}} = Billing.Super.fetch_plan(0)
    end
  end

  describe "fetch_trial_plan!/0" do
    setup do
      TenantFactory.insert(:plan, type: :paid)
      trial_plan = TenantFactory.insert(:plan, type: :trial)

      %{trial_plan: trial_plan}
    end

    test "test", %{trial_plan: trial_plan} do
      assert %Plan{} = fetched_plan = Billing.Super.fetch_trial_plan!()
      assert same_records?(fetched_plan, trial_plan)
    end
  end

  describe "postload_role/1" do
    setup do
      plan = TenantFactory.insert(:plan)

      %{plan: plan}
    end

    test "test", %{plan: plan} do
      TenantRepo.set_skip_org_id()

      plan_without_role = reload!(plan, TenantRepo)
      plan_with_role = plan_without_role |> Billing.Super.postload_role()

      assert same_records?(plan_with_role.role, plan.role)
    end
  end
end
