defmodule Carrier.Core.ApplicableTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Applicable

  describe "apply/2" do
    test "with applicable function" do
      assert Applicable.apply(1, fn x when is_integer(x) -> x + 1 end) == 2
    end

    test "with not applicable function" do
      assert Applicable.apply(1, fn x when is_binary(x) -> x <> "1" end) == 1
    end
  end
end
