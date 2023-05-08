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

  describe "random_integer/2" do
    test "with max and min" do
      max = 100
      min = 0
      random_integer0 = Crypto.random_integer(max, min)
      random_integer1 = Crypto.random_integer(max, min)

      assert is_integer(random_integer0) == true
      assert is_integer(random_integer1) == true
      assert random_integer0 != random_integer1
      assert random_integer0 >= min
      assert random_integer0 <= max
      assert random_integer1 >= min
      assert random_integer1 <= max
    end
  end

  describe "random_float/2" do
    test "with max and min" do
      max = 100.0
      min = 0.0
      random_float0 = Crypto.random_float(max, min)
      random_float1 = Crypto.random_float(max, min)

      assert is_float(random_float0) == true
      assert is_float(random_float1) == true
      assert random_float0 != random_float1
      assert random_float0 >= min
      assert random_float0 <= max
      assert random_float1 >= min
      assert random_float1 <= max
    end
  end

  describe "obfuscate/2" do
    test "with values" do
      value = 123
      obfuscated_value = Crypto.obfuscate([value])

      assert obfuscated_value != value
      assert obfuscated_value |> String.length() >= 8
    end

    test "with value" do
      value = 123
      obfuscated_value = Crypto.obfuscate(value)

      assert obfuscated_value != value
      assert obfuscated_value |> String.length() >= 8
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

  describe "hash/2" do
    test "with md5" do
      data = "hello"
      hash = Crypto.hash(data, :md5)

      assert hash == <<93, 65, 64, 42, 188, 75, 42, 118, 185, 113, 157, 145, 16, 23, 197, 146>>
    end
  end

  describe "hash_to_url64" do
    test "with md5" do
      data = "hello"
      url64_hash = Crypto.hash_to_url64(data, :md5)

      assert url64_hash == "XUFAKrxLKna5cZ2REBfFkg=="
    end
  end
end
