defmodule Carrier.Core.DateHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.DateHelper

  describe "safe_format_date/2" do
    setup do
      Carrier.Cldr.put_locale(:ko)
      date = ~D[2023-02-14]

      %{date: date}
    end

    test "with valid date", %{date: date} do
      assert DateHelper.safe_format_date(date) == "2023년 2월 14일"
    end

    test "with valid datetime" do
      datetime = ~U[2023-02-14 14:49:31.721776Z]

      assert DateHelper.safe_format_date(datetime) == "2023년 2월 14일"
    end

    test "with valid date and format", %{date: date} do
      assert DateHelper.safe_format_date(date, format: "yyyy-MM-dd") == "2023-02-14"
    end

    test "with valid date and invalid format", %{date: date} do
      assert DateHelper.safe_format_date(date, format: "invalid format") == "-"
    end

    test "with invalid date" do
      assert DateHelper.safe_format_date(nil) == "-"
    end

    test "with invalid date and fallback" do
      assert DateHelper.safe_format_date(nil, fallback: "*") == "*"
    end
  end
end
