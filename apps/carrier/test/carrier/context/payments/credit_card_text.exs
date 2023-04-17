defmodule Carrier.Payments.CreditCardTest do
  use Carrier.DataCase, async: true
  alias Carrier.Payments.CreditCard

  describe "format_card_info/1" do
    test "test" do
      credit_card =
        TenantFactory.insert(:credit_card, card_company: "현대", card_number: "41352680****790*")

      assert CreditCard.format_card_info(credit_card) == "현대, **** 790*"
    end
  end
end
