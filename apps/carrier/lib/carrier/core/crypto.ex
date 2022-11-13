defmodule Carrier.Core.Crypto do
  @coder Hashids.new(salt: "carrier", min_len: 5)

  def obfuscate(value) do
    Hashids.encode(@coder, value)
  end

  def deobfuscate!(obfuscated_value) do
    {:ok, [deobfuscate_value]} = Hashids.decode(@coder, obfuscated_value)

    deobfuscate_value
  end
end
