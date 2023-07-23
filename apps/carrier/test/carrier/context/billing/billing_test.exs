defmodule Carrier.BillingTest do
  use Carrier.DataCase
  use Carrier.{Billing, Payments}
  use Oban.Testing, repo: Carrier.Repo
  alias Carrier.Factory
  alias Carrier.ExternalHelper

  describe "start_subscription/1" do
    setup do
      org = Factory.insert(:org)
      admin_role = Factory.insert(:role, name: "Admin")

      Tenant.put_org_id(org.org_id)

      billing_user = Factory.insert(:user, org: org, role: admin_role)
      credit_card = Factory.insert(:credit_card, org_id: org.org_id)

      trial_plan = Factory.insert(:plan, type: :trial)

      %{org: org, trial_plan: trial_plan, billing_user: billing_user, credit_card: credit_card}
    end

    test "with valid params (monthly plan, no active subscription)",
         %{
           org: org,
           trial_plan: trial_plan,
           billing_user: billing_user,
           credit_card: credit_card
         } do
      plan = Factory.insert(:plan, type: :paid, billing_cycle: :monthly)
      Factory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :expired)
      now = ~U[2023-04-10 09:00:00Z]

      # prepare for activation
      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{plan.name}",
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

      # confirmed payment

      assert %Payment{} = payment = Payment |> Repo.get(created_subscription.payment_id)

      assert payment.org_id == created_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # SubscriptionExpiringJob is enqueued

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)

      assert job_args == %{
               "org_id" => created_subscription.org_id,
               "subscription_id" => created_subscription.id
             }

      assert same_values?(job_scheduled_at, created_subscription.end_on)

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> Repo.get_by(status: :pending)

      assert pending_subscription.org_id == created_subscription.org_id
      assert pending_subscription.plan_id == created_subscription.plan_id
      assert pending_subscription.payment_id != nil
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
      plan = Factory.insert(:plan, type: :paid, billing_cycle: :yearly)
      Factory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :expired)
      now = ~U[2023-04-10 09:00:00Z]

      ExternalHelper.TossPayments.prepare_bill(%{
        billing_key: credit_card.billing_key,
        amount: plan.price,
        order_name: "reflow #{plan.name}",
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

    test "with trial plan", %{org: org, trial_plan: trial_plan} do
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: trial_plan.id,
        start_on: now
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert created_subscription.org_id == org.org_id
      assert created_subscription.plan_id == trial_plan.id
      assert created_subscription.payment_id == nil
      assert created_subscription.origin_subscription_id == nil
      assert created_subscription.extension_count == 0
      assert same_values?(created_subscription.start_on, now)
      assert same_values?(created_subscription.end_on, ~U[2023-04-17 09:00:00Z])
      assert created_subscription.status == :active
      assert created_subscription.activated_at != nil
      assert created_subscription.expired_at == nil

      # no pending subscription is created
      assert Subscription |> Repo.all() |> Enum.count() == 1

      # SubscriptionExpiringJob is enqueued

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.SubscriptionExpiringJob)

      assert job_args == %{
               "org_id" => created_subscription.org_id,
               "subscription_id" => created_subscription.id
             }

      assert same_values?(job_scheduled_at, created_subscription.end_on)
    end

    test "with end_on param", %{org: org, trial_plan: trial_plan} do
      now = ~U[2023-04-10 09:00:00Z]
      end_on = now |> Timex.shift(days: 3)

      params = %{
        org_id: org.org_id,
        plan_id: trial_plan.id,
        start_on: now,
        end_on: end_on
      }

      assert {:ok, %Subscription{} = created_subscription} = Billing.start_subscription(params)

      assert same_values?(created_subscription.end_on, end_on)
    end

    test "with invalid plan_id", %{org: org} do
      _plan = Factory.insert(:plan)
      now = ~U[2023-04-10 09:00:00Z]

      params = %{
        org_id: org.org_id,
        plan_id: 0,
        start_on: now
      }

      assert {:error, {:resource_not_found, %{target: Plan}}} = Billing.start_subscription(params)
    end
  end

  describe "expire_subscription/1" do
    setup do
      org = Factory.insert(:org)
      admin_role = Factory.insert(:role, name: "Admin")

      Tenant.put_org_id(org.org_id)

      billing_user = Factory.insert(:user, org: org, role: admin_role)
      credit_card = Factory.insert(:credit_card, org_id: org.org_id)

      %{org: org, billing_user: billing_user, credit_card: credit_card}
    end

    test "with valid params (paid, monthly)", %{
      org: org,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      plan = Factory.insert(:plan, type: :paid, billing_cycle: :monthly)

      subscription =
        Factory.insert(:subscription,
          org_id: org.org_id,
          plan: plan,
          origin_subscription: nil,
          extension_count: 0,
          start_on: ~U[2023-01-31 09:00:00Z],
          end_on: ~U[2023-02-28 09:00:00Z],
          status: :active
        )

      pending_subscription =
        Factory.insert(:subscription,
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
        order_name: "reflow #{plan.name}",
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
               activated_subscription = Subscription |> Repo.get(pending_subscription.id)

      assert activated_subscription.payment_id != nil
      assert activated_subscription.status == :active
      assert activated_subscription.activated_at != nil

      # confirmed payment

      assert %Payment{} = payment = Payment |> Repo.get(activated_subscription.payment_id)

      assert payment.org_id == activated_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert payment.status == :confirmed

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> Repo.get_by(status: :pending)

      assert pending_subscription.org_id == activated_subscription.org_id
      assert pending_subscription.plan_id == activated_subscription.plan_id
      assert pending_subscription.payment_id != nil

      assert pending_subscription.origin_subscription_id ==
               activated_subscription.origin_subscription_id

      assert pending_subscription.extension_count == 2
      assert same_values?(pending_subscription.start_on, activated_subscription.end_on)
      assert same_values?(pending_subscription.end_on, ~U[2023-04-30 09:00:00Z])
      assert pending_subscription.status == :pending
      assert pending_subscription.activated_at == nil
      assert pending_subscription.expired_at == nil

      # pending payment

      assert %Payment{} = payment = Payment |> Repo.get(pending_subscription.payment_id)

      assert payment.org_id == pending_subscription.org_id
      assert payment.credit_card_id == nil
      assert same_values?(payment.amount, plan.price)
      assert same_values?(payment.currency, plan.currency)
      assert payment.status == :pending
    end

    test "with trial subscription and next pending subscription", %{
      org: org,
      billing_user: billing_user,
      credit_card: credit_card
    } do
      trial_plan = Factory.insert(:plan, type: :trial)
      plan = Factory.insert(:plan, type: :paid, billing_cycle: :monthly)

      trial_subscription =
        Factory.insert(:subscription,
          org_id: org.org_id,
          plan: trial_plan,
          start_on: ~U[2023-03-20 15:00:00Z],
          end_on: ~U[2023-03-25 15:00:00Z],
          status: :active
        )

      pending_subscription =
        Factory.insert(:subscription,
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
        order_name: "reflow #{plan.name}",
        customer_email: billing_user.email,
        customer_name: org.name
      })

      assert {:ok, %Subscription{} = _expired_subscription} =
               Billing.expire_subscription(trial_subscription.id)

      # activated pending subscription

      %Subscription{} =
        activated_subscription = Subscription |> Repo.get(pending_subscription.id)

      assert activated_subscription.status == :active
      assert activated_subscription.activated_at != nil
      assert activated_subscription.payment_id != nil

      # created payment

      assert %Payment{} = payment = Payment |> Repo.get(activated_subscription.payment_id)

      assert payment.org_id == activated_subscription.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, plan.price)
      assert payment.status == :confirmed

      # created pending subscription

      assert %Subscription{} =
               pending_subscription = Subscription |> Repo.get_by(status: :pending)

      assert pending_subscription.org_id == activated_subscription.org_id
      assert pending_subscription.plan_id == activated_subscription.plan_id
      assert pending_subscription.payment_id != nil
      assert pending_subscription.origin_subscription_id == activated_subscription.id
      assert pending_subscription.extension_count == 1
      assert same_values?(pending_subscription.start_on, activated_subscription.end_on)
      assert same_values?(pending_subscription.end_on, ~U[2023-05-25 15:00:00Z])
      assert pending_subscription.status == :pending
      assert pending_subscription.activated_at == nil
      assert pending_subscription.expired_at == nil

      # pending payment

      assert %Payment{} = payment = Payment |> Repo.get(pending_subscription.payment_id)

      assert payment.org_id == pending_subscription.org_id
      assert payment.credit_card_id == nil
      assert same_values?(payment.amount, plan.price)
      assert same_values?(payment.currency, plan.currency)
      assert payment.status == :pending
    end

    test "with invalid subscription_id" do
      assert {:error, :subscription_to_expire_not_exist} = Billing.expire_subscription(0)
    end

    test "with not active subscription", %{org: org} do
      subscription = Factory.insert(:subscription, org_id: org.org_id, status: :expired)

      assert {:error, :subscription_to_expire_not_exist} =
               Billing.expire_subscription(subscription.id)
    end
  end

  describe "fetch_subscription/1" do
    setup do
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      subscription = Factory.insert(:subscription, org_id: org.org_id, status: :active)

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

    test "with deleted subscription", %{subscription: subscription} do
      subscription |> soft_delete!()

      assert {:error, {:resource_not_found, %{target: Subscription}}} =
               Billing.fetch_subscription(subscription.id)
    end
  end

  describe "fetch_active_subscription/0" do
    setup do
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      plan = Factory.insert(:plan)

      %{org: org, plan: plan}
    end

    test "with valid subscription", %{org: org, plan: plan} do
      credit_card = Factory.insert(:credit_card, org_id: org.org_id)
      payment = Factory.insert(:payment, org_id: org.org_id, credit_card: credit_card)

      subscription =
        Factory.insert(:subscription,
          status: :active,
          org_id: org.org_id,
          plan: plan,
          payment: payment
        )

      assert {:ok, %Subscription{} = fetched_subscription} = Billing.fetch_active_subscription()

      assert same_records?(fetched_subscription, subscription)
      assert same_records?(fetched_subscription.plan, plan)
      assert same_records?(fetched_subscription.plan.role, plan.role)
      assert same_records?(fetched_subscription.payment, payment)
      assert same_records?(fetched_subscription.payment.credit_card, credit_card)
    end

    test "with deleted subscription", %{org: org, plan: plan} do
      subscription =
        Factory.insert(:subscription,
          status: :active,
          org_id: org.org_id,
          plan: plan,
          deleted_at: DateTime.utc_now()
        )

      assert {:error, {:resource_not_found, %{target: Subscription}}} =
               Billing.fetch_subscription(subscription.id)
    end

    test "without payment", %{org: org, plan: plan} do
      Factory.insert(:subscription,
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
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      plan = Factory.insert(:plan)

      %{org: org, plan: plan}
    end

    test "with valid subscription", %{org: org, plan: plan} do
      credit_card = Factory.insert(:credit_card, org_id: org.org_id)
      payment = Factory.insert(:payment, org_id: org.org_id, credit_card: credit_card)

      subscription =
        Factory.insert(:subscription,
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

    test "with deleted subscription", %{org: org, plan: plan} do
      subscription =
        Factory.insert(:subscription,
          status: :pending,
          org_id: org.org_id,
          plan: plan,
          deleted_at: DateTime.utc_now()
        )

      assert {:error, {:resource_not_found, %{target: Subscription}}} =
               Billing.fetch_subscription(subscription.id)
    end

    test "without payment", %{org: org, plan: plan} do
      Factory.insert(:subscription,
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
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      trial_plan = Factory.insert(:plan, type: :trial)

      %{org: org, trial_plan: trial_plan}
    end

    test "with active trial subscription", %{org: org, trial_plan: trial_plan} do
      subscription =
        Factory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :active)

      assert %Subscription{} = fetched_subscription = Billing.get_active_trial_subscription()
      assert same_records?(fetched_subscription, subscription)
    end

    test "with deleted subscription", %{org: org, trial_plan: trial_plan} do
      Factory.insert(:subscription,
        org_id: org.org_id,
        plan: trial_plan,
        status: :active,
        deleted_at: DateTime.utc_now()
      )

      assert Billing.get_active_trial_subscription() == nil
    end

    test "without active trial subscription", %{org: org, trial_plan: trial_plan} do
      _expired_trial_subscription =
        Factory.insert(:subscription,
          org_id: org.org_id,
          plan: trial_plan,
          status: :expired
        )

      assert Billing.get_active_trial_subscription() == nil
    end
  end

  describe "have_active_subscription/0" do
    setup do
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      %{org: org}
    end

    test "with trial plan", %{org: org} do
      trial_plan = Factory.insert(:plan, type: :trial)

      _subscription =
        Factory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :active)

      assert Billing.have_active_subscription?() == true
    end

    test "with paid plan", %{org: org} do
      plan = Factory.insert(:plan, type: :paid)

      _subscription =
        Factory.insert(:subscription, org_id: org.org_id, plan: plan, status: :active)

      assert Billing.have_active_subscription?() == true
    end
  end

  describe "have_active_non_trial_subscription/0" do
    setup do
      org = Factory.insert(:org)

      Tenant.put_org_id(org.org_id)

      %{org: org}
    end

    test "with trial plan", %{org: org} do
      trial_plan = Factory.insert(:plan, type: :trial)

      _subscription =
        Factory.insert(:subscription, org_id: org.org_id, plan: trial_plan, status: :active)

      assert Billing.have_active_non_trial_subscription?() == false
    end

    test "with paid plan", %{org: org} do
      plan = Factory.insert(:plan, type: :paid)

      _subscription =
        Factory.insert(:subscription, org_id: org.org_id, plan: plan, status: :active)

      assert Billing.have_active_non_trial_subscription?() == true
    end
  end
end
