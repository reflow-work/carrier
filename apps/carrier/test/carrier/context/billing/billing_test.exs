defmodule Carrier.BillingTest do
  use Carrier.DataCase
  use Carrier.{Billing, Payments}
  use Oban.Testing, repo: Carrier.TenantRepo
  alias Carrier.TenantFactory
  alias Carrier.ExternalHelper

  @moduletag repo: TenantRepo

  describe "start_subscription/1" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      billing_user = TenantFactory.insert(:user, org: org)
      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      trial_plan = TenantFactory.insert(:plan, type: :trial)

      %{org: org, trial_plan: trial_plan, billing_user: billing_user, credit_card: credit_card}
    end

    test "with valid params (monthly plan, not first time subscription, expired prev subscription)",
         %{
           org: org,
           trial_plan: trial_plan,
           billing_user: billing_user,
           credit_card: credit_card
         } do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)
      TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :expired)
      now = ~U[2023-04-10 09:00:00Z]

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{Plan.get_full_name(plan)}",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert created_subscription.org_id == org.org_id
      assert created_subscription.plan_id == plan.id
      assert created_subscription.payment_id != nil
      assert created_subscription.origin_subscription_id == nil
      assert created_subscription.extension_count == 0
      assert same_values?(created_subscription.start_on, now)
      assert same_values?(created_subscription.end_on, ~U[2023-05-10 09:00:00Z])
      assert created_subscription.status == :active
      assert created_subscription.activated_at != nil
      assert created_subscription.expired_at == nil

      # no trial subscription is created & new pending subscription is created
      assert Subscription |> TenantRepo.all() |> Enum.count() == 3

      # created payment

      assert %Payment{} = payment = Payment |> TenantRepo.get(created_subscription.payment_id)

      assert payment.org_id == created_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # SubscriptionExpiringJob is enqueued

      TenantRepo.set_skip_org_id()

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)

      assert job_args == %{
               "org_id" => created_subscription.org_id,
               "subscription_id" => created_subscription.id
             }

      assert same_values?(job_scheduled_at, created_subscription.end_on)

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> TenantRepo.get_by(status: :pending)

      assert pending_subscription.org_id == created_subscription.org_id
      assert pending_subscription.plan_id == created_subscription.plan_id
      assert pending_subscription.payment_id == nil
      assert pending_subscription.origin_subscription_id == created_subscription.id
      assert pending_subscription.extension_count == 1
      assert same_values?(pending_subscription.start_on, created_subscription.end_on)
      assert same_values?(pending_subscription.end_on, ~U[2023-06-10 09:00:00Z])
      assert pending_subscription.status == :pending
      assert pending_subscription.activated_at == nil
      assert pending_subscription.expired_at == nil
    end

    test "with yearly plan", %{
      org: org,
      trial_plan: trial_plan,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :yearly)
      TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :expired)
      now = ~U[2023-04-10 09:00:00Z]

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{Plan.get_full_name(plan)}",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert same_values?(created_subscription.start_on, now)
      assert same_values?(created_subscription.end_on, ~U[2024-04-10 09:00:00Z])
    end

    test "with prev active trial subscription", %{org: org, trial_plan: trial_plan} do
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)

      trial_subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: trial_plan,
          start_on: ~U[2023-03-20 15:00:00Z],
          end_on: ~U[2023-04-20 15:00:00Z],
          status: :active
        )

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
      assert created_subscription.extension_count == 0
      assert same_values?(created_subscription.start_on, trial_subscription.end_on)
      assert same_values?(created_subscription.end_on, ~U[2023-05-20 15:00:00Z])
      assert created_subscription.status == :pending
      assert created_subscription.activated_at == nil
      assert created_subscription.expired_at == nil

      # no trial subscription is created & no pending subscription is created
      assert Subscription |> TenantRepo.all() |> Enum.count() == 2

      # no SubscriptionExpiringJob is enqueued

      TenantRepo.set_skip_org_id()

      assert [] = all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)
    end

    test "with first time subscription", %{org: org, trial_plan: trial_plan} do
      TenantFactory.insert(:property,
        key: "trial_promotion_end_on",
        type: :datetime,
        value: ~U[2023-03-01 15:00:00Z]
      )

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

      # trial subscription is created & no pending subscription is created
      assert Subscription |> TenantRepo.all() |> Enum.count() == 2

      # created trial subscription

      %Subscription{} =
        created_trial_subscription = Subscription |> TenantRepo.get_by(plan_id: trial_plan.id)

      assert created_trial_subscription.org_id == org.org_id
      assert created_trial_subscription.plan_id == trial_plan.id
      assert created_trial_subscription.payment_id == nil
      assert created_subscription.origin_subscription_id == nil
      assert created_subscription.extension_count == 0
      assert same_values?(created_trial_subscription.start_on, now)
      assert same_values?(created_trial_subscription.end_on, ~U[2023-04-17 09:00:00Z])
      assert created_trial_subscription.status == :active
      assert created_trial_subscription.activated_at != nil
      assert created_trial_subscription.expired_at == nil

      # SubscriptionExpiringJob for trial subscription is enqueued

      TenantRepo.set_skip_org_id()

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)

      assert job_args == %{
               "org_id" => created_trial_subscription.org_id,
               "subscription_id" => created_trial_subscription.id
             }

      assert same_values?(job_scheduled_at, created_trial_subscription.end_on)
    end

    test "with first time subscription (before trial promotion ends)", %{
      org: org,
      trial_plan: trial_plan
    } do
      TenantFactory.insert(:property,
        key: "trial_promotion_end_on",
        type: :datetime,
        value: ~U[2023-05-04 15:00:00Z]
      )

      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert same_values?(created_subscription.start_on, ~U[2023-05-11 15:00:00Z])
      assert same_values?(created_subscription.end_on, ~U[2023-06-11 15:00:00Z])

      # trial subscription is created & no pending subscription is created
      assert Subscription |> TenantRepo.all() |> Enum.count() == 2

      # created trial subscription

      %Subscription{} =
        created_trial_subscription = Subscription |> TenantRepo.get_by(plan_id: trial_plan.id)

      assert created_trial_subscription.org_id == org.org_id
      assert created_trial_subscription.plan_id == trial_plan.id
      assert created_trial_subscription.payment_id == nil
      assert created_subscription.origin_subscription_id == nil
      assert created_subscription.extension_count == 0
      assert same_values?(created_trial_subscription.start_on, now)
      assert same_values?(created_trial_subscription.end_on, ~U[2023-05-11 15:00:00Z])
      assert created_trial_subscription.status == :active
      assert created_trial_subscription.activated_at != nil
      assert created_trial_subscription.expired_at == nil

      # SubscriptionExpiringJob for trial subscription is enqueued

      TenantRepo.set_skip_org_id()

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)

      assert job_args == %{
               "org_id" => created_trial_subscription.org_id,
               "subscription_id" => created_trial_subscription.id
             }

      assert same_values?(job_scheduled_at, created_trial_subscription.end_on)
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

  describe "expire_subscription/1" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      billing_user = TenantFactory.insert(:user, org: org)
      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      %{org: org, billing_user: billing_user, credit_card: credit_card}
    end

    test "with valid params (basic, monthly)", %{
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
          extension_count: 0,
          start_on: ~U[2023-01-31 09:00:00Z],
          end_on: ~U[2023-02-28 09:00:00Z],
          status: :active
        )

      pending_subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: subscription,
          extension_count: 1,
          start_on: ~U[2023-02-28 09:00:00Z],
          end_on: ~U[2023-03-31 09:00:00Z],
          status: :pending
        )

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{Plan.get_full_name(plan)}",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      assert {:ok, %Subscription{} = expired_subscription} =
               Billing.expire_subscription(subscription.id)

      assert same_records?(expired_subscription, subscription)
      assert expired_subscription.status == :expired
      assert expired_subscription.expired_at != nil

      # activate pending subscription

      assert %Subscription{} =
               activated_subscription = Subscription |> TenantRepo.get(pending_subscription.id)

      assert activated_subscription.payment_id != nil
      assert activated_subscription.status == :active
      assert activated_subscription.activated_at != nil

      # created payment

      assert %Payment{} = payment = Payment |> TenantRepo.get(activated_subscription.payment_id)

      assert payment.org_id == activated_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> TenantRepo.get_by(status: :pending)

      assert pending_subscription.org_id == activated_subscription.org_id
      assert pending_subscription.plan_id == activated_subscription.plan_id
      assert pending_subscription.payment_id == nil

      assert pending_subscription.origin_subscription_id ==
               activated_subscription.origin_subscription_id

      assert pending_subscription.extension_count == 2
      assert same_values?(pending_subscription.start_on, activated_subscription.end_on)
      assert same_values?(pending_subscription.end_on, ~U[2023-04-30 09:00:00Z])
      assert pending_subscription.status == :pending
      assert pending_subscription.activated_at == nil
      assert pending_subscription.expired_at == nil
    end

    test "with trial subscription and next pending subscription", %{
      org: org,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      trial_plan = TenantFactory.insert(:plan, type: :trial)
      plan = TenantFactory.insert(:plan, type: :basic, billing_cycle: :monthly)

      trial_subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: trial_plan,
          start_on: ~U[2023-03-20 15:00:00Z],
          end_on: ~U[2023-03-25 15:00:00Z],
          status: :active
        )

      pending_subscription =
        TenantFactory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: nil,
          extension_count: 0,
          start_on: ~U[2023-03-25 15:00:00Z],
          end_on: ~U[2023-04-25 15:00:00Z],
          status: :pending
        )

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{Plan.get_full_name(plan)}",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      assert {:ok, %Subscription{} = _expired_subscription} =
               Billing.expire_subscription(trial_subscription.id)

      # activated pending subscription

      %Subscription{} =
        activated_subscription = Subscription |> TenantRepo.get(pending_subscription.id)

      assert activated_subscription.status == :active
      assert activated_subscription.activated_at != nil
      assert activated_subscription.payment_id != nil

      # created payment

      assert %Payment{} = payment = Payment |> TenantRepo.get(activated_subscription.payment_id)

      assert payment.org_id == activated_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> TenantRepo.get_by(status: :pending)

      assert pending_subscription.org_id == activated_subscription.org_id
      assert pending_subscription.plan_id == activated_subscription.plan_id
      assert pending_subscription.payment_id == nil
      assert pending_subscription.origin_subscription_id == activated_subscription.id
      assert pending_subscription.extension_count == 1
      assert same_values?(pending_subscription.start_on, activated_subscription.end_on)
      assert same_values?(pending_subscription.end_on, ~U[2023-05-25 15:00:00Z])
      assert pending_subscription.status == :pending
      assert pending_subscription.activated_at == nil
      assert pending_subscription.expired_at == nil
    end

    test "with invalid subscription_id" do
      assert {:error, :subscription_can_not_be_expired} = Billing.expire_subscription(0)
    end

    test "with not active subscription", %{org: org} do
      subscription = TenantFactory.insert(:subscription, org_id: org.org_id, status: :expired)

      assert {:error, :subscription_can_not_be_expired} =
               Billing.expire_subscription(subscription.id)
    end
  end

  describe "fetch_subscription/1" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      subscription = TenantFactory.insert(:subscription, org_id: org.org_id, status: :active)

      %{subscription: subscription}
    end

    test "with valid params", %{subscription: subscription} do
      assert {:ok, %Subscription{} = fetched_subscription} =
               Billing.fetch_subscription(subscription.id)

      assert same_records?(fetched_subscription, subscription)
      assert %Plan{} = fetched_subscription.plan
      assert %Payment{} = fetched_subscription.payment
      assert %CreditCard{} = fetched_subscription.payment.credit_card
    end
  end

  describe "fetch_active_subscription/0" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      plan = TenantFactory.insert(:plan)

      %{org: org, plan: plan}
    end

    test "test", %{org: org, plan: plan} do
      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)
      payment = TenantFactory.insert(:payment, org_id: org.org_id, credit_card: credit_card)

      subscription =
        TenantFactory.insert(:subscription,
          status: :active,
          org_id: org.org_id,
          plan: plan,
          payment: payment
        )

      assert {:ok, %Subscription{} = fetched_subscription} = Billing.fetch_active_subscription()

      assert same_records?(fetched_subscription, subscription)
      assert same_records?(fetched_subscription.plan, plan)
      assert same_records?(fetched_subscription.payment, payment)
      assert same_records?(fetched_subscription.payment.credit_card, credit_card)
    end

    test "without payment", %{org: org, plan: plan} do
      TenantFactory.insert(:subscription,
        status: :active,
        org_id: org.org_id,
        plan: plan,
        payment: nil
      )

      assert {:ok, %Subscription{} = fetched_subscription} = Billing.fetch_active_subscription()

      assert fetched_subscription.payment == nil
    end
  end

  describe "fetch_pending_subscription/0" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      plan = TenantFactory.insert(:plan)

      %{org: org, plan: plan}
    end

    test "test", %{org: org, plan: plan} do
      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)
      payment = TenantFactory.insert(:payment, org_id: org.org_id, credit_card: credit_card)

      subscription =
        TenantFactory.insert(:subscription,
          status: :pending,
          org_id: org.org_id,
          plan: plan,
          payment: payment
        )

      assert {:ok, %Subscription{} = fetched_subscription} = Billing.fetch_pending_subscription()

      assert same_records?(fetched_subscription, subscription)
      assert same_records?(fetched_subscription.plan, plan)
      assert same_records?(fetched_subscription.payment, payment)
      assert same_records?(fetched_subscription.payment.credit_card, credit_card)
    end

    test "without payment", %{org: org, plan: plan} do
      TenantFactory.insert(:subscription,
        status: :pending,
        org_id: org.org_id,
        plan: plan,
        payment: nil
      )

      assert {:ok, %Subscription{} = fetched_subscription} = Billing.fetch_pending_subscription()

      assert fetched_subscription.payment == nil
    end
  end

  describe "get_active_trial_subscription/0" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      trial_plan = TenantFactory.insert(:plan, type: :trial)

      %{org: org, trial_plan: trial_plan}
    end

    test "with active trial subscription", %{org: org, trial_plan: trial_plan} do
      active_trial_subscription =
        TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :active)

      assert %Subscription{} = fetched_subscription = Billing.get_active_trial_subscription()
      assert same_records?(fetched_subscription, active_trial_subscription)
    end

    test "without active trial subscription", %{org: org, trial_plan: trial_plan} do
      _expired_trial_subscription =
        TenantFactory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :expired)

      assert Billing.get_active_trial_subscription() == nil
    end
  end
end
