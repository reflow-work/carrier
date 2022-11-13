defmodule Carrier.Core.CryptoTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Crypto

  describe "obfuscate/1" do
    test "with value" do
      value = 123
      obfuscated_value = Crypto.obfuscate(value)

      assert obfuscated_value != value
      assert obfuscated_value |> String.length() >= 5
    end
  end

  describe "deobfuscate!/1" do
    test "with obfuscated_value" do
      value = 123
      obfuscated_value = Crypto.obfuscate(value)

      assert Crypto.deobfuscate!(obfuscated_value) == value
    end
  end
end
