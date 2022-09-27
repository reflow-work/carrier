defmodule Carrier.Core.DateTimeHelperTest do
  use ExUnit.Case, async: true
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
end
