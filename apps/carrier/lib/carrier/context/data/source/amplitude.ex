defmodule Carrier.Data.Source.Amplitude do
  @behaviour Carrier.Data.Source

  alias Carrier.Core.Browser

  defmodule Dashboard do
    defstruct [:url]
  end

  ### behaviors

  @impl true
  def validate_conn(:amplitude, _credentials, _opts) do
    :ok
  end

  def get_dashboard_image_binary(_data_source, dashboard_url) do
    Browser.Lambda.screenshot(dashboard_url, :amplitude)
  end

  def validate_dashboard_url(nil) do
    false
  end

  def validate_dashboard_url(dashboard_url) do
    Regex.match?(dashboard_url_format(), dashboard_url)
  end

  def dashboard_url_format() do
    ~r(^https://app.amplitude.com/analytics/share)
  end
end
