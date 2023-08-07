defmodule Carrier.Data.Source.Amplitude do
  @behaviour Carrier.Data.Source

  use Carrier.Integrations
  alias Carrier.Data.Block
  alias Carrier.Core.{Async, Browser}
  alias Carrier.Uploader

  defmodule Dashboard do
    defstruct [:name, :url]

    def new(%{name: name, url: url}) do
      %__MODULE__{name: name, url: url}
    end
  end

  ### behaviors

  @impl true
  def validate_conn(:amplitude, _credentials, _opts) do
    :ok
  end


  @impl true
  def load_raw_data(
        %{
          data_source_info: %{params: %{dashboards: dashboard_params}}
        },
        %DataSource{source: :amplitude}
      ) do
    with dashboards = dashboard_params |> Enum.map(&Dashboard.new/1),
         dashboard_urls = dashboards |> Enum.map(& &1.url),
         {:ok, dashboard_image_binaries} <- dashboard_urls |> do_list_dashboard_image_binaries_async() do
      {:ok, %{dashboards: dashboards, dashboard_image_binaries: dashboard_image_binaries}}
    end
  end

  @impl true
  def transform_data(%{org_id: org_id}, %DataSource{source: :amplitude}, %{
        dashboards: dashboards,
        dashboard_image_binaries: dashboard_image_binaries
      }) do
    with {:ok, dashboard_image_urls} <-
           dashboard_image_binaries
           |> Async.map(&Uploader.upload(:report_storage, org_id, &1, :png))
           |> Async.unwrap_map_ok_results() do
      {:ok, %{dashboards: dashboards, dashboard_image_urls: dashboard_image_urls}}
    end
  end

  @impl true
  def data_to_threads(_params, %DataSource{source: :amplitude}, %{
        dashboards: dashboards,
        dashboard_image_urls: dashboard_image_urls
      }) do
    threads =
      [dashboards, dashboard_image_urls]
      |> Enum.zip_with(fn [%Dashboard{name: name, url: url}, dashboard_image_url] ->
        [
          Block.link(name, url),
          Block.image(name, dashboard_image_url, name),
          Block.button("Open Original Image", dashboard_image_url)
        ]
      end)

    {:ok, threads}
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

  defp do_list_dashboard_image_binaries_async(dashboard_urls) do
    dashboard_urls
    |> Async.map(fn dashboard_url -> get_dashboard_image_binary(nil, dashboard_url) end)
    |> Async.unwrap_map_ok_results()
  end
end
