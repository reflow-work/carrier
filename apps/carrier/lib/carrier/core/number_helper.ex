defmodule Carrier.Core.NumberHelper do
  require Logger
  alias Carrier.Core.Cldr

  def safe_format_money(%Decimal{} = decimal, currency) do
    safe_format_money(decimal |> Decimal.to_float(), currency)
  end

  def safe_format_money(number, currency)
      when is_number(number) and (is_binary(currency) or is_atom(currency)) do
    case Cldr.Number.to_string(number, currency: currency) do
      {:ok, result} ->
        result

      {:error, _reason} ->
        Logger.warn(
          "safe_format_money: invalid number #{inspect(number)} or currency #{inspect(currency)}"
        )

        "-"
    end
  end

  def safe_format_money(number, currency) do
    Logger.warn(
      "safe_format_money: invalid number #{inspect(number)} or currency #{inspect(currency)}"
    )

    "-"
  end
end
