defmodule Carrier.BillingTest do
  use Carrier.DataCase, async: true
  use Carrier.{Billing, Payments}
  use Oban.Testing, repo: Carrier.TenantRepo
  alias Carrier.ExternalHelper

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
      TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan)
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
      assert created_subscription.extension_count == 0
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
      TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan)
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
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      billing_user = TenantFactory.insert(:user, org: org)
      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      %{org: org, billing_user: billing_user, credit_card: credit_card}
    end

    test "with valid params (basic, monthly, with prev_subscription)", %{
      org: org,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)

      prev_subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: nil,
          prev_subscription: nil,
          extension_count: 0,
          start_on: ~U[2023-01-31 09:00:00Z],
          end_on: ~U[2023-02-28 09:00:00Z],
          status: :active
        )

      subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: prev_subscription,
          prev_subscription: prev_subscription,
          extension_count: 1,
          start_on: ~U[2023-02-28 09:00:00Z],
          end_on: ~U[2023-03-31 09:00:00Z],
          status: :pending
        )

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow Basic Monthly Plan",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      assert {:ok, %Subscription{} = activated_subscription} =
               Billing.activate_subscription(subscription.id)

      assert activated_subscription.id == subscription.id
      assert activated_subscription.status == :active
      assert activated_subscription.activated_at != nil
      assert activated_subscription.payment_id != nil

      # expired prev subscription

      prev_subscription = Subscription |> TenantRepo.get(prev_subscription.id)

      assert prev_subscription.status == :expired

      # created payment

      assert %Payment{} = payment = Payment |> TenantRepo.get(activated_subscription.payment_id)

      assert payment.org_id == activated_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # created next subscription

      assert %Subscription{} =
               next_subscription =
               Subscription |> TenantRepo.get_by(prev_subscription_id: subscription.id)

      assert next_subscription.org_id == activated_subscription.org_id
      assert next_subscription.plan_id == activated_subscription.plan_id
      assert next_subscription.payment_id == nil

      assert next_subscription.origin_subscription_id ==
               activated_subscription.origin_subscription_id

      assert next_subscription.prev_subscription_id == activated_subscription.id
      assert next_subscription.extension_count == 2
      assert same_values?(next_subscription.start_on, ~U[2023-03-31 09:00:00Z])
      assert same_values?(next_subscription.end_on, ~U[2023-04-30 09:00:00Z])
      assert next_subscription.status == :pending
    end

    test "with invalid subscription_id" do
      assert {:error, :subscription_can_not_be_activated} = Billing.activate_subscription(0)
    end

    test "with not pending subscription" do
      subscription = TenantFactory.insert(:subscription, status: :active)

      assert {:error, :subscription_can_not_be_activated} =
               Billing.activate_subscription(subscription.id)
    end

    test "with subscription that has no prev_subscription", %{
      org: org,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)

      subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: nil,
          prev_subscription: nil,
          extension_count: 0,
          start_on: ~U[2023-01-31 09:00:00Z],
          end_on: ~U[2023-02-28 09:00:00Z],
          status: :pending
        )

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow Basic Monthly Plan",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      assert {:ok, %Subscription{} = activated_subscription} =
               Billing.activate_subscription(subscription.id)

      assert %Payment{} = Payment |> TenantRepo.get(activated_subscription.payment_id)

      assert %Subscription{} =
               next_subscription =
               Subscription |> TenantRepo.get_by(prev_subscription_id: subscription.id)

      assert next_subscription.origin_subscription_id == activated_subscription.id
      assert next_subscription.prev_subscription_id == activated_subscription.id
      assert next_subscription.extension_count == 1
    end
  end
end
