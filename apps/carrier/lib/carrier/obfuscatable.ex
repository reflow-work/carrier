defmodule Carrier.Obfuscatable do
  require Logger

  defdelegate obfuscate(data), to: Carrier.Obfuscatable.Protocol

  def obfuscate(id, module) do
    module_key = hash_module(module)

    Carrier.Core.Crypto.obfuscate([id, module_key])
  end

  def deobfuscate!(obfuscated_key, module) when is_binary(obfuscated_key) do
    [key, module_key] = Carrier.Core.Crypto.deobfuscate!(obfuscated_key)

    ^module_key = hash_module(module)

    key
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      raise ArgumentError, "invalid obfuscated key"
  end

  defp hash_module(module) do
    module |> Atom.to_string() |> String.to_charlist() |> Enum.sum()
  end
end

defprotocol Carrier.Obfuscatable.Protocol do
  @fallback_to_any true

  def obfuscate(data)
end

defimpl Carrier.Obfuscatable.Protocol, for: Integer do
  def obfuscate(data) do
    Carrier.Core.Crypto.obfuscate(data)
  end
end

defimpl Carrier.Obfuscatable.Protocol, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :id)

    unless Map.has_key?(struct, key) do
      raise ArgumentError,
            "cannot derive Carrier.Obfuscatable.Protocol for struct #{inspect(module)} " <>
              "because it does not have key #{inspect(key)}. Please pass " <>
              "the :key option when deriving"
    end

    quote do
      defimpl Carrier.Obfuscatable.Protocol, for: unquote(module) do
        def obfuscate(%{unquote(key) => nil}) do
          raise ArgumentError,
                "cannot obfuscate key of #{inspect(unquote(module))}, " <>
                  "key #{inspect(unquote(key))} contains a nil value"
        end

        def obfuscate(%{unquote(key) => key}) when is_integer(key) do
          Carrier.Obfuscatable.obfuscate(key, unquote(module))
        end
      end

      defimpl Phoenix.Param, for: unquote(module) do
        def to_param(data) do
          Carrier.Obfuscatable.obfuscate(data)
        end
      end
    end
  end

  def obfuscate(%_module{id: nil}) do
    raise ArgumentError, "cannot obfuscate key of struct, key :id contains a nil value"
  end

  def obfuscate(%module{id: id}) do
    Carrier.Obfuscatable.obfuscate(id, module)
  end

  def obfuscate(data) do
    raise Protocol.UndefinedError, protocol: @protocol, value: data
  end
end
