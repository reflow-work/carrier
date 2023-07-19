defmodule Carrier.Billing.PlanTest do
  use ExUnit.Case, async: true
  alias Carrier.Billing.Plan
  alias Carrier.TenantFactory

  describe "check_subscribable/1" do
    test "with subscribable plan" do
      plan = TenantFactory.build(:plan, type: :paid)

      assert :ok = Plan.check_subscribable(plan)
    end

    test "with non-subscribable plan" do
      plan = TenantFactory.build(:plan, type: :trial)

      assert {:error, :plan_not_subscribable} = Plan.check_subscribable(plan)
    end
  end

  describe "calc_start_on/3" do
    setup do
      origin_start_on = ~U[2023-04-11 09:00:00Z]

      %{origin_start_on: origin_start_on}
    end

    test "with trial plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :trial)

      assert Plan.calc_start_on(plan, origin_start_on, 0) == ~U[2023-04-11 09:00:00Z]

      assert_raise FunctionClauseError, fn ->
        Plan.calc_start_on(plan, origin_start_on, 1)
      end
    end

    test "with monthly plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :paid, billing_cycle: :monthly)

      assert Plan.calc_start_on(plan, origin_start_on, 0) == ~U[2023-04-11 09:00:00Z]
      assert Plan.calc_start_on(plan, origin_start_on, 1) == ~U[2023-05-11 09:00:00Z]
    end

    test "with yearly plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :paid, billing_cycle: :yearly)

      assert Plan.calc_start_on(plan, origin_start_on, 0) == ~U[2023-04-11 09:00:00Z]
      assert Plan.calc_start_on(plan, origin_start_on, 1) == ~U[2024-04-11 09:00:00Z]
    end
  end

  describe "calc_end_on/3" do
    setup do
      origin_start_on = ~U[2023-04-11 09:00:00Z]

      %{origin_start_on: origin_start_on}
    end

    test "with trial plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :trial)

      assert Plan.calc_end_on(plan, origin_start_on, 0) == ~U[2023-04-18 09:00:00Z]

      assert_raise FunctionClauseError, fn ->
        Plan.calc_end_on(plan, origin_start_on, 1)
      end
    end

    test "with monthly plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :paid, billing_cycle: :monthly)

      assert Plan.calc_end_on(plan, origin_start_on, 0) == ~U[2023-05-11 09:00:00Z]
      assert Plan.calc_end_on(plan, origin_start_on, 1) == ~U[2023-06-11 09:00:00Z]
    end

    test "with yearly plan", %{origin_start_on: origin_start_on} do
      plan = TenantFactory.build(:plan, type: :paid, billing_cycle: :yearly)

      assert Plan.calc_end_on(plan, origin_start_on, 0) == ~U[2024-04-11 09:00:00Z]
      assert Plan.calc_end_on(plan, origin_start_on, 1) == ~U[2025-04-11 09:00:00Z]
    end
  end
end
