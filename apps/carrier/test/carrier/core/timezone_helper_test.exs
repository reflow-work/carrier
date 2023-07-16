defmodule Carrier.Core.TimezoneHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.TimezoneHelper

  describe "get_utc_offset_s/1" do
    test "with positive offset" do
      assert TimezoneHelper.get_utc_offset_s("Asia/Seoul") == 9 * 60 * 60
    end

    test "with negative offset" do
      assert TimezoneHelper.get_utc_offset_s("America/New_York") == -5 * 60 * 60
    end

    test "with zero offset" do
      assert TimezoneHelper.get_utc_offset_s("Etc/UTC") == 0
    end
  end

  describe "apply_timezone/1" do
    test "with valid timezone" do
      timezone = "Asia/Seoul"
      datetime = ~U[2023-04-17 00:00:00Z]

      TimezoneHelper.put_timezone(timezone)

      assert timezone_applyed_datetime = TimezoneHelper.apply_timezone(datetime)
      assert timezone_applyed_datetime.time_zone == timezone
      assert Timex.equal?(timezone_applyed_datetime, datetime)
    end

    test "with invalid timezone" do
      TimezoneHelper.put_timezone("invalid")

      assert TimezoneHelper.apply_timezone(~U[2023-04-17 00:00:00Z]) == ~U[2023-04-17 00:00:00Z]
    end

    test "without timezone" do
      assert TimezoneHelper.apply_timezone(~U[2023-04-17 00:00:00Z]) == ~U[2023-04-17 00:00:00Z]
    end
  end

  describe "safe_timezone/1" do
    test "with valid timezone" do
      assert TimezoneHelper.safe_timezone("Asia/Seoul") == "Asia/Seoul"
    end

    test "with invalid timezone" do
      assert TimezoneHelper.safe_timezone("invalid") == "Etc/UTC"
    end

    test "with nil timezone" do
      assert TimezoneHelper.safe_timezone(nil) == "Etc/UTC"
    end
  end

  describe "safe_format/1" do
    test "with valid timezone" do
      assert TimezoneHelper.safe_format("Asia/Seoul") == "KST(+09:00:00)"
    end

    test "with invalid timezone" do
      assert TimezoneHelper.safe_format("invalid") == "-"
    end
  end
end
