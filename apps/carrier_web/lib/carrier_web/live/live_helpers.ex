defmodule CarrierWeb.LiveHelpers do
  alias Phoenix.LiveView.JS
  alias Carrier.Core.{TimezoneHelper, DateHelper, DateTimeHelper}

  def format_number(s) do
    case Carrier.Core.Cldr.Number.to_string(s) do
      {:ok, n} -> n
      {:error, _msg} -> "0"
    end
  end

  def format_date(nil) do
    "-"
  end

  def format_date(datetime, opts \\ []) do
    datetime
    |> TimezoneHelper.apply_timezone()
    |> DateHelper.safe_format_date(opts)
  end

  def format_datetime(nil) do
    "-"
  end

  def format_datetime(datetime) do
    datetime
    |> TimezoneHelper.apply_timezone()
    |> DateTimeHelper.safe_format()
  end

  def format_money(number, currency) do
    Carrier.Core.NumberHelper.safe_format_money(number, currency)
  end

  def format_timezone(timezone) do
    TimezoneHelper.safe_format(timezone)
  end

  def current_datetime!(timezone) do
    DateTime.now!(timezone)
  end

  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end
end
