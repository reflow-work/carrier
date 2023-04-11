defmodule Carrier.Billing.PlanTest do
  use ExUnit.Case, async: true
  alias Carrier.Billing.Plan
  alias Carrier.TenantFactory

  describe "calc_end_on/3" do
    setup do
      now = ~U[2023-04-11 09:00:00Z]

      %{now: now}
    end

    test "with trial plan", %{now: now} do
      plan = TenantFactory.build(:plan, type: :trial)

      assert Plan.calc_end_on(plan, now, 1) == ~U[2023-04-18 09:00:00Z]

      assert_raise CaseClauseError, fn ->
        Plan.calc_end_on(plan, now, 2) == ~U[2023-04-18 09:00:00Z]
      end
    end

    test "with monthly plan", %{now: now} do
      plan = TenantFactory.build(:plan, type: :basic, billing_cycle: :monthly)

      assert Plan.calc_end_on(plan, now, 1) == ~U[2023-05-11 09:00:00Z]
      assert Plan.calc_end_on(plan, now, 2) == ~U[2023-06-11 09:00:00Z]
    end

    test "with yearly plan", %{now: now} do
      plan = TenantFactory.build(:plan, type: :basic, billing_cycle: :yearly)

      assert Plan.calc_end_on(plan, now, 1) == ~U[2024-04-11 09:00:00Z]
      assert Plan.calc_end_on(plan, now, 2) == ~U[2025-04-11 09:00:00Z]
    end
  end
end
