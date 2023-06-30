defmodule CarrierWeb.LiveHelpers do
  alias Phoenix.LiveView.JS
  alias Carrier.Core.{TimezoneHelper, DateHelper}

  def format_number(s) do
    case Carrier.Core.Cldr.Number.to_string(s) do
      {:ok, n} -> n
      {:error, _msg} -> "0"
    end
  end

  def format_date(datetime) do
    datetime
    |> TimezoneHelper.apply_timezone()
    |> DateHelper.safe_format_date()
  end

  def format_money(number, currency) do
    Carrier.Core.NumberHelper.safe_format_money(number, currency)
  end

  def current_datetime!(timezone) do
    DateTime.now!(timezone)
  end

  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end
end
