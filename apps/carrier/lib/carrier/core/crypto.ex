defmodule Carrier.Core.Crypto do
  def obfuscate(coder \\ default_coder(), values)

  def obfuscate(coder, values) when is_list(values) do
    Hashids.encode(coder, values)
  end

  def obfuscate(coder, value) when is_integer(value) and value > 0 do
    obfuscate(coder, [value])
  end

  def deobfuscate!(coder \\ default_coder(), obfuscated_value) do
    {:ok, deobfuscate_values} = Hashids.decode(coder, obfuscated_value)

    case deobfuscate_values do
      [value] -> value
      values -> values
    end
  end

  defp default_coder() do
    salt = Application.get_env(:carrier, :hashids_salt)

    Hashids.new(salt: salt, min_len: 5)
  end
end
