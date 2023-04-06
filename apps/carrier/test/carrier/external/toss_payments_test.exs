defmodule Carrier.External.TossPaymentsTest do
  use ExUnit.Case, async: true
  alias Carrier.External.TossPayments
  alias Carrier.External
  alias Carrier.ExternalHelper

  @success_resp Carrier.Fixture.json("toss_payments/issue_billing_auth.success.json")

  describe "issue_billing_auth/2" do
    setup do
      bypass = Bypass.open(port: 4101)

      %{bypass: bypass}
    end

    test "with valid params", %{bypass: bypass} do
      ExternalHelper.expect(
        bypass,
        :post,
        "/v1/billing/authorizations/issue",
        {:json, @success_resp},
        validate: fn _params, body ->
          assert body == %{"authKey" => "auth_key", "customerKey" => "78wBm"}
        end
      )

      assert {:ok, %External.Model.CreditCardInfo{} = credit_card} =
               TossPayments.issue_billing_auth("auth_key", "78wBm")

      assert credit_card.provider == :toss_payments
      assert credit_card.billing_key == "ueAUrnr8njSl-8Uub_ZZ192yXRApNep8zhJzpH5xNDE="
      assert credit_card.customer_key == "78wBm"
      assert credit_card.card_company == "현대"
      assert credit_card.card_number == "41352680****123*"
    end
  end
end
