defmodule Carrier.Core.TimeHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.TimeHelper

  describe "from!/1" do
    test "with full params" do
      assert TimeHelper.from!(hour: 1, minute: 23, second: 45) == ~T[01:23:45]
    end
  end

  describe "to_utc_time/2" do
    test "with not date diff condition" do
      assert Timex.equal?(TimeHelper.to_utc_time(~T[10:00:00], "Asia/Seoul"), ~T[01:00:00])
    end

    test "with date diff condition" do
      assert Timex.equal?(TimeHelper.to_utc_time(~T[08:00:00], "Asia/Seoul"), ~T[23:00:00])
    end
  end

  describe "from_utc_time/2" do
    test "with not date diff condition" do
      assert Timex.equal?(TimeHelper.from_utc_time(~T[01:00:00], "Asia/Seoul"), ~T[10:00:00])
    end

    test "with date diff condition" do
      assert Timex.equal?(TimeHelper.from_utc_time(~T[23:00:00], "Asia/Seoul"), ~T[08:00:00])
    end
  end

  describe "calc_day_diff_to_utc_time/2" do
    test "with not date diff condition" do
      assert TimeHelper.calc_day_diff_to_utc_time(~T[10:00:00], "Asia/Seoul") == 0
    end

    test "with positive date diff condition" do
      assert TimeHelper.calc_day_diff_to_utc_time(~T[23:00:00], "America/Toronto") == 1
    end

    test "with negative date diff condition" do
      assert TimeHelper.calc_day_diff_to_utc_time(~T[08:00:00], "Asia/Seoul") == -1
    end
  end

  describe "calc_day_diff_from_utc_time/2" do
    test "with not date diff condition" do
      assert TimeHelper.calc_day_diff_from_utc_time(~T[10:00:00], "Asia/Seoul") == 0
    end

    test "with positive date diff condition" do
      assert TimeHelper.calc_day_diff_from_utc_time(~T[23:00:00], "Asia/Seoul") == 1
    end

    test "with negative date diff condition" do
      assert TimeHelper.calc_day_diff_from_utc_time(~T[01:00:00], "America/Toronto") == -1
    end
  end
end
