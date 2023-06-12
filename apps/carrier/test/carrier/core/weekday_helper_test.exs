defmodule Carrier.Core.WeekdayHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.WeekdayHelper

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
end
