defmodule Carrier.Core.NillableTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Nillable

  describe "map/2" do
    test "with nil" do
      assert Nillable.map(nil, &(&1 + 1)) == nil
    end

    test "with not nil" do
      assert Nillable.map(1, &(&1 + 1)) == 2
    end
  end

  describe "fallback/2" do
    test "with nil" do
      assert Nillable.fallback(nil, 1) == 1
    end

    test "with not nil" do
      assert Nillable.fallback(2, 1) == 2
    end
  end
end
