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

  describe "run/3" do
    test "with nil" do
      assert Nillable.run(1, nil, &(&1 + 1)) == 1
    end

    test "with not nil and arity 1 fun" do
      assert Nillable.run(1, 1, &(&1 + 1)) == 2
    end

    test "with not nil and arity 2 fun" do
      assert Nillable.run(1, 1, &(&1 + &2)) == 2
    end
  end

  describe "run_until/3" do
    test "with nil" do
      assert Nillable.run_until(1, nil, &(&1 + 1)) == 2
    end

    test "with not nil and arity 1 fun" do
      assert Nillable.run_until(1, 1, &(&1 + 1)) == 1
    end
  end
end
