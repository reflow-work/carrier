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
      assert credit_card.billing_key == "ueAUrnr8njSl-8Uub_ZZ192yXRApNep8zhJzpH5xNDE="
      assert credit_card.customer_key == params.customer_key
      assert credit_card.card_company == "현대"
      assert credit_card.card_number == "41352680****123*"
    end

    test "with duplicated org_id", %{params: params} do
      {:ok, %CreditCard{}} = Payments.create_credit_card(:toss_payments, params)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Payments.create_credit_card(:toss_payments, params)

      assert [org_id: {"has already been taken", _}] = errors
    end

    test "with duplicated org_id but deleted", %{params: params} do
      {:ok, %CreditCard{} = credit_card} = Payments.create_credit_card(:toss_payments, params)

      credit_card |> Ecto.Changeset.change(deleted_at: DateTime.utc_now()) |> TenantRepo.update!()

      assert {:ok, %CreditCard{}} = Payments.create_credit_card(:toss_payments, params)
    end
  end

  describe "process_payment/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      credit_card = TenantFactory.insert(:credit_card, org_id: org.org_id)

      %{org: org, credit_card: credit_card}
    end

    test "with valid params", %{org: org, credit_card: credit_card} do
      assert {:ok, %Payment{} = payment} =
               Payments.process_payment(%{
                 org_id: org.org_id,
                 credit_card_id: credit_card.id,
                 amount: 10_000,
                 currency: :KRW
               })

      assert payment.org_id == org.org_id
      assert payment.credit_card_id == credit_card.id
      assert same_values?(payment.amount, 10_000)
      assert payment.currency == :KRW

      # TODO
      # assert payment.status == :confirmed
      # assert payment.payload == ?
    end

    # TODO

    # test "with invalid credit_card_id", %{org: org} do
    # end

    # test "with expired credit_card_id", %{org: org, credit_card: credit_card} do
    # end
  end
end
