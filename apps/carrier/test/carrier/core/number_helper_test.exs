defmodule Carrier.Core.NumberHelperTest do
  use ExUnit.Case, async: true

  describe "safe_format_money/2" do
    test "with valid number and currency" do
      assert Carrier.Core.NumberHelper.safe_format_money(1000, "USD") == "US$1,000.00"
      assert Carrier.Core.NumberHelper.safe_format_money(1000, :USD) == "US$1,000.00"
    end

    test "with invalid number" do
      assert Carrier.Core.NumberHelper.safe_format_money(nil, "USD") == "-"
    end

    test "with invalid currency" do
      assert Carrier.Core.NumberHelper.safe_format_money(1000, "ABC") == "-"
    end
  end
end
