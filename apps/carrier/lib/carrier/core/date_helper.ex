defmodule Carrier.Core.DateHelper do
  alias Carrier.Core.{Cldr, OkTuple}

  def safe_format_date(maybe_date_or_datetime, opts \\ []) do
    format = opts |> Keyword.get(:format, :long)
    fallback = opts |> Keyword.get(:fallback, "-")

    Cldr.Date.to_string(maybe_date_or_datetime, format: format)
    |> OkTuple.unwrap(fallback)
  end
end
