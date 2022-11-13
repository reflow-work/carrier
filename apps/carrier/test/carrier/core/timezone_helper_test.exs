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
end
