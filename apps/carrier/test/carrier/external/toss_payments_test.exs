defmodule Carrier.External.TossPaymentsTest do
  use ExUnit.Case
  alias Carrier.External.TossPayments
  alias Carrier.External
  alias Carrier.ExternalHelper

  # TODO: do async test
  # https://github.com/dashbitco/bytepack_archive/blob/main/apps/bytepack/test/support/stripe_helpers.ex

  setup do
    bypass = Bypass.open(port: 4101)

    %{bypass: bypass}
  end

  @success_resp Carrier.Fixture.json("toss_payments/issue_billing_auth.success.json")

  describe "issue_billing_auth/2" do
    test "with valid params", %{bypass: bypass} do
      ExternalHelper.expect(
        bypass,
        :post,
        "/v1/billing/authorizations/issue",
        {:json, @success_resp},
        validate: fn _params, body ->
          assert body == %{"authKey" => "auth_key", "customerKey" => "678wBmAE"}
        end
      )

      assert {:ok, %External.Model.CreditCardInfo{} = credit_card} =
               TossPayments.issue_billing_auth("auth_key", "678wBmAE")

      assert credit_card.provider == :toss_payments
      assert credit_card.billing_key == @success_resp["billingKey"]
      assert credit_card.customer_key == @success_resp["customerKey"]
      assert credit_card.card_company == @success_resp["cardCompany"]
      assert credit_card.card_number == @success_resp["cardNumber"]
    end
  end

  @success_resp Carrier.Fixture.json("toss_payments/bill.success.json")

  describe "bill/1" do
    test "with valid params", %{bypass: bypass} do
      params = %{
        billing_key: "u7tiHB8fpmCTclS3d2J8xTsQtYnrF93C9S4s0g7ThIc=",
        amount: Decimal.new(100_000),
        customer_key: "678wBmAE",
        order_id: "nmaBsy8a",
        order_name: "Pro 연간 플랜 구독",
        customer_email: "json@refow.work",
        customer_name: "json"
      }

      ExternalHelper.expect(
        bypass,
        :post,
        "/v1/billing/#{params.billing_key}",
        {:json, @success_resp},
        validate: fn _params, body ->
          assert body == %{
                   "amount" => 100_000,
                   "customerKey" => "678wBmAE",
                   "orderId" => "nmaBsy8a",
                   "orderName" => "Pro 연간 플랜 구독",
                   "customerEmail" => "json@refow.work",
                   "customerName" => "json"
                 }
        end
      )

      assert {:ok, %External.Model.PaymentInfo{} = payment_info} = TossPayments.bill(params)

      assert payment_info.provider == :toss_payments
      assert payment_info.provider_key == "9o5gEq4k6YZ1aOwX7K8mO2B6RE5Q1WVyQxzvNPGenpDAlBdb"
      assert payment_info.confirmed_at == ~U[2023-04-07 07:28:46Z]
      assert payment_info.payload == @success_resp
    end
  end
end
