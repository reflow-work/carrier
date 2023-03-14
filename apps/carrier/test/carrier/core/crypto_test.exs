defmodule Carrier.Core.CryptoTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Crypto

  describe "random_string/1" do
    test "with length" do
      length = 10
      random_string0 = Crypto.random_string(length)
      random_string1 = Crypto.random_string(length)

      assert is_binary(random_string0) == true
      assert is_binary(random_string1) == true
      assert random_string0 |> String.length() == length
      assert random_string1 |> String.length() == length
      assert random_string0 != random_string1
    end
  end

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
