defmodule Carrier.ObfuscatableTest do
  use ExUnit.Case, async: true
  alias Carrier.Obfuscatable

  defmodule Test0 do
    defstruct [:id, :name]
  end

  defmodule Test1 do
    defstruct [:id, :name]
  end

  describe "obfuscate/deobfuscate" do
    test "with valid params" do
      obfuscated_value = Obfuscatable.obfuscate(1, Test0)

      assert is_binary(obfuscated_value)
      assert obfuscated_value |> Obfuscatable.deobfuscate!(Test0) == 1
    end

    test "deobfuscate with invalid module" do
      obfuscated_value = Obfuscatable.obfuscate(1, Test0)

      assert_raise ArgumentError, fn ->
        Obfuscatable.deobfuscate!(obfuscated_value, Test1)
      end
    end
  end

  describe "obfuscate/deobfuscate via Carrier.Obfuscatable.Protocol" do
    test "with valid params" do
      obfuscated_value = Obfuscatable.obfuscate(%Test0{id: 1, name: "test"})

      assert is_binary(obfuscated_value)
      assert obfuscated_value |> Obfuscatable.deobfuscate!(Test0) == 1
    end
  end
end
