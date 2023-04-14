defmodule Carrier.BillingTest do
  use Carrier.DataCase, async: true
  use Carrier.Billing
  use Oban.Testing, repo: Carrier.TenantRepo

  @moduletag repo: TenantRepo

  describe "start_subscription/1" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      trial_plan = TenantFactory.insert(:plan, type: :trial)

      %{org: org, trial_plan: trial_plan}
    end

    test "with valid params (monthly plan, not first time subscription)", %{
      org: org,
      trial_plan: trial_plan
    } do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)
      TenantFactory.insert(:subscription, org_id: org.org_id, plan_id: trial_plan.id)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert created_subscription.org_id == org.org_id
      assert created_subscription.plan_id == plan.id
      assert created_subscription.payment_id == nil
      assert created_subscription.origin_subscription_id == nil
      assert created_subscription.prev_subscription_id == nil
      assert same_values?(created_subscription.start_on, now)
      assert same_values?(created_subscription.end_on, ~U[2023-05-10 09:00:00Z])
      assert created_subscription.status == :pending
      assert created_subscription.activated_at == nil
      assert created_subscription.expired_at == nil

      # no trial subscription is created
      assert Subscription |> TenantRepo.all() |> Enum.count() == 2

      # SubscriptionActivatingJob is enqueued

      TenantRepo.set_skip_org_id()

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionActivatingJob)

      assert job_args == %{
               "org_id" => created_subscription.org_id,
               "subscription_id" => created_subscription.id
             }

      assert same_values?(job_scheduled_at, created_subscription.start_on)
    end

    test "with yearly plan", %{org: org, trial_plan: trial_plan} do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :yearly)
      TenantFactory.insert(:subscription, org_id: org.org_id, plan_id: trial_plan.id)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert same_values?(created_subscription.start_on, now)
      assert same_values?(created_subscription.end_on, ~U[2024-04-10 09:00:00Z])
    end

    test "with first time subscription", %{org: org, trial_plan: trial_plan} do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert same_values?(created_subscription.start_on, ~U[2023-04-17 09:00:00Z])
      assert same_values?(created_subscription.end_on, ~U[2023-05-17 09:00:00Z])

      %Subscription{} =
        created_trial_subscription = Subscription |> TenantRepo.get_by(plan_id: trial_plan.id)

      assert created_trial_subscription.org_id == org.org_id
      assert created_trial_subscription.plan_id == trial_plan.id
      assert created_trial_subscription.payment_id == nil
      assert created_trial_subscription.prev_subscription_id == nil
      assert same_values?(created_trial_subscription.start_on, now)
      assert same_values?(created_trial_subscription.end_on, ~U[2023-04-17 09:00:00Z])
      assert created_trial_subscription.status == :active
      assert same_values?(created_trial_subscription.activated_at, now)
      assert created_trial_subscription.expired_at == nil
    end

    test "with invalid plan_id", %{org: org} do
      _plan = TenantFactory.insert(:plan)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: 0,
        start_on: now
      }

      assert {:error, {:resource_not_found, %{target: Plan}}} = Billing.start_subscription(params)
    end

    test "with not subscribable plan", %{org: org} do
      not_subscribable_plan = TenantFactory.insert(:plan, type: :trial)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: not_subscribable_plan.id,
        start_on: now
      }

      assert {:error, :plan_not_subscribable} = Billing.start_subscription(params)
    end
  end

  describe "activate_subscription/1" do
    # test "with valid params" do
    # end

    # test "with invalid subscription_id" do
    # end

    # test "with not pending subscription" do
    # end

    # test "with subscription that has no prev_subscription" do
    # end
  end
end
