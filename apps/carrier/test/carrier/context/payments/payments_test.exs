defmodule Carrier.PaymentsTest do
  use Carrier.DataCase, async: true
  use Carrier.Payments
  alias Carrier.ExternalHelper
  alias Carrier.Core.Crypto

  @moduletag repo: Carrier.TenantRepo

  describe "create_credit_card/1 with toss_payments" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      params = %{
        org_id: org.org_id,
        auth_key: "auth_key",
        customer_key: Crypto.obfuscate(org.org_id)
      }

      ExternalHelper.TossPayments.prepare_issue_billing_auth(
        params.auth_key,
        params.customer_key
      )

      %{org: org, params: params}
    end

    test "with valid params", %{org: org, params: params} do
      assert {:ok, %CreditCard{} = credit_card} =
               Payments.create_credit_card(:toss_payments, params)

      assert credit_card.org_id == org.org_id
      assert credit_card.provider == :toss_payments
      assert credit_card.billing_key == "u7tiHB8fpmCTclS3d2J8xTsQtYnrF93C9S4s0g7ThIc="
      assert credit_card.customer_key == params.customer_key
      assert credit_card.card_company == "현대"
      assert credit_card.card_number == "41352680****790*"
    end

    test "with duplicated org_id", %{params: params} do
      {:ok, %CreditCard{}} = Payments.create_credit_card(:toss_payments, params)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Payments.create_credit_card(:toss_payments, params)

      assert [org_id: {"has already been taken", _}] = errors
    end

    test "with duplicated org_id but deleted", %{params: params} do
      {:ok, %CreditCard{} = credit_card} = Payments.create_credit_card(:toss_payments, params)

      credit_card |> soft_delete!()

      assert {:ok, %CreditCard{}} = Payments.create_credit_card(:toss_payments, params)
    end
  end

  describe "fetch_default_credit_card/0" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      %{credit_card: credit_card}
    end

    test "with credit_card", %{credit_card: credit_card} do
      assert {:ok, fetched_credit_card} = Payments.fetch_default_credit_card()

      assert same_records?(fetched_credit_card, credit_card)
    end

    test "with deleted credit_card", %{credit_card: credit_card} do
      credit_card |> soft_delete!()

      assert {:error, {:resource_not_found, %{target: CreditCard}}} =
               Payments.fetch_default_credit_card()
    end
  end

  describe "create_payment/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      params = %{
        org_id: org.org_id,
        amount: Decimal.new(100_000),
        currency: :KRW
      }

      %{params: params}
    end

    test "with valid params", %{params: params} do
      assert {:ok, %Payment{} = payment} = Payments.create_payment(params)

      assert same_fields?(payment, params, [:org_id, :amount, :currency])
      assert payment.status == :pending
    end
  end

  describe "process_payment/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      payment = TenantFactory.insert(:payment, org_id: org.org_id, status: :pending)

      params = %{
        order_id: "2MsAs0Bk0wKML",
        order_name: "Pro 연간 플랜 구독",
        customer_email: "json@reflow.work",
        customer_name: "json"
      }

      %{payment: payment, params: params}
    end

    test "with valid params", %{payment: payment, params: params} do
      credit_card =
        TenantFactory.insert(:credit_card, org_id: payment.org_id, provider: :toss_payments)

      resp =
        ExternalHelper.TossPayments.prepare_bill(%{
          billing_key: credit_card.billing_key,
          amount: payment.amount,
          order_id: "2MsAs0Bk0wKML",
          order_name: params.order_name,
          customer_email: params.customer_email,
          customer_name: params.customer_name
        })

      assert {:ok, %Payment{} = payment} = Payments.process_payment(payment.id, params)

      assert payment.credit_card_id == credit_card.id
      assert payment.status == :confirmed
      assert payment.provider == :toss_payments
      assert payment.provider_key == "2MsAs0Bk0wKML"
      assert payment.item == "Pro 연간 플랜 구독"
      assert payment.payload == resp
    end

    test "without credit_card", %{payment: payment, params: params} do
      assert {:error, {:resource_not_found, %{target: CreditCard}}} =
               Payments.process_payment(payment.id, params)
    end

    test "with expired credit_card", %{payment: payment, params: params} do
      credit_card =
        TenantFactory.insert(:credit_card, org_id: payment.org_id, provider: :toss_payments)

      ExternalHelper.TossPayments.prepare_bill(
        %{
          billing_key: credit_card.billing_key,
          amount: payment.amount,
          order_id: params.order_id,
          order_name: params.order_name,
          customer_email: params.customer_email,
          customer_name: params.customer_name
        },
        fail: true
      )

      assert {:error, %Payment{} = payment} = Payments.process_payment(payment.id, params)

      assert payment.status == :failed

      assert payment.payload == %{
               "code" => "INVALID_CARD_EXPIRATION",
               "message" => "카드 정보를 다시 확인해주세요. (유효기간)"
             }
    end
  end

  describe "list_confirmed_payments/0" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      now = DateTime.utc_now()

      _pending_payment =
        TenantFactory.insert(:payment,
          org_id: org.org_id,
          credit_card: credit_card,
          status: :pending
        )

      confirmed_payment0 =
        TenantFactory.insert(:payment,
          org_id: org.org_id,
          credit_card: credit_card,
          status: :confirmed,
          confirmed_at: now |> Timex.shift(days: -3)
        )

      confirmed_payment1 =
        TenantFactory.insert(:payment,
          org_id: org.org_id,
          credit_card: credit_card,
          status: :confirmed,
          confirmed_at: now |> Timex.shift(days: -2)
        )

      _deleted_payment =
        TenantFactory.insert(:payment,
          org_id: org.org_id,
          credit_card: credit_card,
          status: :confirmed,
          confirmed_at: now |> Timex.shift(days: -1),
          deleted_at: now
        )

      _failed_payment =
        TenantFactory.insert(:payment,
          org_id: org.org_id,
          credit_card: credit_card,
          status: :failed
        )

      _others_confirmed_payment = TenantFactory.insert(:payment, status: :confirmed)

      %{payment: [confirmed_payment0, confirmed_payment1]}
    end

    test "test", %{payment: [payment0, payment1]} do
      assert {:ok, [fetched_payment0, fetched_payment1]} = Payments.list_confirmed_payments()
      assert same_records?(fetched_payment0, payment1)
      assert same_records?(fetched_payment1, payment0)
    end
  end
end
