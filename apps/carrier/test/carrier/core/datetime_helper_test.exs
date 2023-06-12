defmodule Carrier.Core.DateTimeHelperTest do
  use Carrier.CommonCase, async: true
  alias Carrier.Core.DateTimeHelper

  describe "get_next_with_time/2" do
    test "with not passed time" do
      utc_datetime = DateTime.from_naive!(~N[2018-01-01 12:00:00], "Etc/UTC")
      utc_time = ~T[13:00:00]

      assert DateTimeHelper.get_next_with_time(utc_datetime, utc_time) ==
               DateTime.from_naive!(~N[2018-01-01 13:00:00], "Etc/UTC")
    end

    test "with passed time" do
      utc_datetime = DateTime.from_naive!(~N[2018-01-01 12:00:00], "Etc/UTC")
      utc_time = ~T[12:00:00]

      assert DateTimeHelper.get_next_with_time(utc_datetime, utc_time) ==
               DateTime.from_naive!(~N[2018-01-02 12:00:00], "Etc/UTC")
    end
  end

  describe "calc_next_with_weekday_time/3" do
    test "with passed weekday" do
      # tuesday
      utc_datetime = ~U[2023-06-13 09:00:00Z]
      utc_weekday = 1
      utc_time = ~T[13:00:00]

      assert DateTimeHelper.calc_next_with_weekday_time(utc_datetime, utc_weekday, utc_time) ==
               ~U[2023-06-19 13:00:00Z]
    end

    test "with same weekday and not passed time" do
      # tuesday
      utc_datetime = ~U[2023-06-13 09:00:00Z]
      utc_weekday = 2
      utc_time = ~T[10:00:00]

      assert DateTimeHelper.calc_next_with_weekday_time(utc_datetime, utc_weekday, utc_time) ==
               ~U[2023-06-13 10:00:00Z]
    end

    test "with same weekday and passed time" do
      # tuesday
      utc_datetime = ~U[2023-06-13 11:00:00Z]
      utc_weekday = 2
      utc_time = ~T[10:00:00]

      assert DateTimeHelper.calc_next_with_weekday_time(utc_datetime, utc_weekday, utc_time) ==
               ~U[2023-06-20 10:00:00Z]
    end

    test "with not passed weekday" do
      # tuesday
      utc_datetime = ~U[2023-06-13 11:00:00Z]
      utc_weekday = 4
      utc_time = ~T[10:00:00]

      assert DateTimeHelper.calc_next_with_weekday_time(utc_datetime, utc_weekday, utc_time) ==
               ~U[2023-06-15 10:00:00Z]
    end
  end

  describe "calc_next/3" do
    test "with monthly cycle" do
      start_datetime = ~U[2023-01-31 09:00:00Z]
      cycle = :monthly

      assert DateTimeHelper.calc_next(start_datetime, cycle, 1) ==
               ~U[2023-02-28 09:00:00Z]

      assert DateTimeHelper.calc_next(start_datetime, cycle, 2) ==
               ~U[2023-03-31 09:00:00Z]

      assert DateTimeHelper.calc_next(start_datetime, cycle, 3) ==
               ~U[2023-04-30 09:00:00Z]
    end

    test "with yearly period" do
      start_datetime = ~U[2024-02-29 09:00:00Z]
      cycle = :yearly

      assert DateTimeHelper.calc_next(start_datetime, cycle, 1) ==
               ~U[2025-02-28 09:00:00Z]

      assert DateTimeHelper.calc_next(start_datetime, cycle, 4) ==
               ~U[2028-02-29 09:00:00Z]
    end
  end

  describe "calc_next_hourly" do
    test "with not sharp datetime" do
      assert same_values?(
               DateTimeHelper.calc_next_hourly(~U[2023-01-31 09:11:50.123Z]),
               ~U[2023-01-31 10:00:00Z]
             )
    end

    test "with sharp datetime" do
      assert same_values?(
               DateTimeHelper.calc_next_hourly(~U[2023-01-31 09:00:00Z]),
               ~U[2023-01-31 10:00:00Z]
             )
    end
  end

  describe "max/2" do
    test "with first datetime is greater" do
      datetime1 = ~U[2023-01-31 09:00:00Z]
      datetime2 = ~U[2023-01-30 09:00:00Z]

      assert DateTimeHelper.max(datetime1, datetime2) == datetime1
    end

    test "with second datetime is greater" do
      datetime1 = ~U[2023-01-30 09:00:00Z]
      datetime2 = ~U[2023-01-31 09:00:00Z]

      assert DateTimeHelper.max(datetime1, datetime2) == datetime2
    end

    test "with equal datetimes" do
      datetime = ~U[2023-01-31 09:00:00Z]

      assert DateTimeHelper.max(datetime, datetime) == datetime
    end
  end

  describe "min/2" do
    test "with first datetime is greater" do
      datetime1 = ~U[2023-01-31 09:00:00Z]
      datetime2 = ~U[2023-01-30 09:00:00Z]

      assert DateTimeHelper.min(datetime1, datetime2) == datetime2
    end

    test "with second datetime is greater" do
      datetime1 = ~U[2023-01-30 09:00:00Z]
      datetime2 = ~U[2023-01-31 09:00:00Z]

      assert DateTimeHelper.min(datetime1, datetime2) == datetime1
    end

    test "with equal datetimes" do
      datetime = ~U[2023-01-31 09:00:00Z]

      assert DateTimeHelper.min(datetime, datetime) == datetime
    end
  end

  describe "truncate/2" do
    @datetime ~U[2023-01-31 09:11:50.123Z]

    test "with :second precision" do
      assert same_values?(DateTimeHelper.truncate(@datetime, :second), ~U[2023-01-31 09:11:50Z])
    end

    test "with :minute precision" do
      assert same_values?(DateTimeHelper.truncate(@datetime, :minute), ~U[2023-01-31 09:11:00Z])
    end

    test "with :hour precision" do
      assert same_values?(DateTimeHelper.truncate(@datetime, :hour), ~U[2023-01-31 09:00:00Z])
    end
  end
end
