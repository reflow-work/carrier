defmodule Carrier.Core.StringHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.StringHelper

  describe "split_leading/2" do
    test "with match" do
      assert StringHelper.split_leading("   abcdef   ", " ") == {"   ", "abcdef   "}
    end

    test "without match" do
      assert StringHelper.split_leading("abcdef   ", " ") == {"", "abcdef   "}
    end
  end

  describe "split_trailing/2" do
    test "with match" do
      assert StringHelper.split_trailing("   abcdef   ", " ") == {"   ", "   abcdef"}
    end

    test "without match" do
      assert StringHelper.split_trailing("   abcdef", " ") == {"", "   abcdef"}
    end
  end
end
