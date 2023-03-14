defmodule Carrier.Core.CryptoTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Crypto

  describe "obfuscate/2" do
    test "with values" do
      value = 123
      obfuscated_value = Crypto.obfuscate([value])

      assert obfuscated_value != value
      assert obfuscated_value |> String.length() >= 5
    end

    test "with value" do
      value = 123
      obfuscated_value = Crypto.obfuscate(value)

      assert obfuscated_value != value
      assert obfuscated_value |> String.length() >= 5
    end
  end

  describe "deobfuscate!/2" do
    test "with obfuscated values" do
      value = [123, 456]
      obfuscated_value = Crypto.obfuscate(value)

      assert Crypto.deobfuscate!(obfuscated_value) == value
    end

    test "with obfuscated value" do
      value = 123
      obfuscated_value = Crypto.obfuscate(value)

      assert Crypto.deobfuscate!(obfuscated_value) == value
    end
  end
end
