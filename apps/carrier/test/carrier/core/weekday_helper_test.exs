defmodule Carrier.Core.WeekdayHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.WeekdayHelper
  alias Carrier.Core.Cldr

  describe "add/2" do
    test "with no over" do
      assert WeekdayHelper.add(1, 3) == 4
    end

    test "with less 1" do
      assert WeekdayHelper.add(1, -3) == 5
    end

    test "with over 7" do
      assert WeekdayHelper.add(3, 6) == 2
    end

    test "with 0" do
      assert WeekdayHelper.add(1, -1) == 7
    end

    test "with 7" do
      assert WeekdayHelper.add(1, 6) == 7
    end
  end

  describe "to_utc_weekday/3" do
    test "with over" do
      assert WeekdayHelper.to_utc_weekday(1, ~T[08:00:00], "Asia/Seoul") == 7
    end
  end

  describe "from_utc_weekday/3" do
    test "with over" do
      assert WeekdayHelper.from_utc_weekday(7, ~T[23:00:00], "Asia/Seoul") == 1
    end
  end

  describe "safe_format_weekday/2" do
    test "with abbreviated format" do
      Cldr.put_locale("en")

      assert WeekdayHelper.safe_format_weekday(1) == "Mon"
    end

    test "with wide format" do
      Cldr.put_locale("en")

      assert WeekdayHelper.safe_format_weekday(1, :wide) == "Monday"
    end
  end
end
