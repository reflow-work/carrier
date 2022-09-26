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
end
