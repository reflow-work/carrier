defmodule Carrier.Core.DateHelper do
  alias Carrier.Cldr
  alias Carrier.Core.OkTuple

  def safe_format_date(maybe_date, opts \\ []) do
    format = opts |> Keyword.get(:format, :long)
    fallback = opts |> Keyword.get(:fallback, "-")

    Cldr.Date.to_string(maybe_date, format: format)
    |> OkTuple.unwrap(fallback)
  end
end
