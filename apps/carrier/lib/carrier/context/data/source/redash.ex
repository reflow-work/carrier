defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source

  use Carrier.Integrations
  alias Carrier.External.RedashAPI
  alias Carrier.Uploader
  alias Carrier.Core.Async

  defmodule Pagination do
    defstruct [:page, :page_size, :total]

    def new(%{"page" => page, "page_size" => page_size, "count" => count}) do
      %__MODULE__{page: page, page_size: page_size, total: count}
    end
  end

  defmodule Dashboard do
    defstruct [:id, :name, :public_url]

    def new(%{"id" => id, "name" => name} = params) do
      %__MODULE__{id: id, name: name, public_url: params["public_url"]}
    end
  end

  ### behaviors

  @impl true
  def validate_conn(:redash, credentials, _opts) do
    case RedashAPI.list_dashboards(1, credentials) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:invalid_conn_info, reason}}
    end
  end

  @impl true
  def load_raw_data(
        %{data_source_info: %{params: %{dashboards: dashboard_params}}},
        %DataSource{source: :redash} = data_source
      ) do
    credentials = DataSource.to_credentials(data_source)

    with dashboard_ids = dashboard_params |> Enum.map(& &1.id),
         {:ok, dashboards} <- dashboard_ids |> do_list_dashboards_async(credentials),
         {:ok, dashboard_image_binaries} <- dashboards |> do_list_dashboard_image_binaries_async() do
      {:ok, %{dashboards: dashboards, dashboard_image_binaries: dashboard_image_binaries}}
    end
  end

  @impl true
  def transform_data(%{org_id: org_id}, %DataSource{source: :redash}, %{
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

  def list_dashboards(%DataSource{source: :redash} = data_source) do
    credentials = data_source |> DataSource.to_credentials()

    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok,
         %{
           dashboards: dashboards,
           pagination: %Pagination{page: page, page_size: page_size, total: total}
         }} =
          RedashAPI.list_dashboards(page, credentials)

        last_page = div(total, page_size) + 1

        case last_page == page do
          true -> {dashboards, nil}
          false -> {dashboards, page + 1}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end

  defp do_list_dashboards_async(dashboard_ids, credentials) do
    dashboard_ids
    |> Async.map(fn dashboard_id -> RedashAPI.get_dashboard(dashboard_id, credentials) end)
    |> Async.unwrap_map_ok_results()
  end

  defp do_list_dashboard_image_binaries_async(dashboards) do
    dashboards
    |> Async.map(fn dashboard -> RedashAPI.get_dashboard_screenshot(dashboard.public_url) end)
    |> Async.unwrap_map_ok_results()
  end
end
