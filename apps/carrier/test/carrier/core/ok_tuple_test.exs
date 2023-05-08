defmodule Carrier.Core.OkTupleTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.OkTuple

  describe "fallback/2" do
    test "with ok tuple" do
      assert OkTuple.unwrap({:ok, 1}, 2) == 1
    end

    test "with error tuple" do
      assert OkTuple.unwrap({:error, "reason"}, 2) == 2
    end

    test "with error tuple without fallback" do
      assert OkTuple.unwrap({:error, "reason"}) == nil
    end

    test "with error atom" do
      assert OkTuple.unwrap(:error, 2) == 2
    end

    test "with others" do
      assert_raise FunctionClauseError, fn ->
        OkTuple.unwrap("not a tuple", 2)
      end
    end
  end

  describe "map/2" do
    test "with ok" do
      assert OkTuple.map({:ok, 1}, &(&1 + 1)) == 2
    end

    test "with error" do
      assert OkTuple.map({:error, "reason"}, &(&1 + 1)) == {:error, "reason"}
    end
  end
end
