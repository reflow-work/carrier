defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source

  use Carrier.Integrations
  alias Carrier.Data.Block
  alias Carrier.External.RedashAPI
  alias Carrier.Uploader
  alias Carrier.Core.{Async, Nillable}

  defmodule Pagination do
    defstruct [:page, :page_size, :total]

    def new(%{"page" => page, "page_size" => page_size, "count" => count}) do
      %__MODULE__{page: page, page_size: page_size, total: count}
    end
  end

  defmodule Dashboard do
    alias Carrier.Data.Source.Redash.Widget

    defstruct [:id, :name, :slug, :is_draft, :is_archived, :public_url, :widgets]

    def new(
          %{
            "id" => id,
            "name" => name,
            "is_draft" => is_draft,
            "is_archived" => is_archived,
            "slug" => slug
          } = params
        ) do
      %__MODULE__{
        id: id |> to_string(),
        name: name,
        slug: slug,
        is_draft: is_draft,
        is_archived: is_archived,
        public_url: params["public_url"],
        widgets: (params["widgets"] || []) |> Enum.map(&Widget.new/1)
      }
    end

    def url(%__MODULE__{id: id, slug: slug}, host) do
      "#{host}/dashboards/#{id}-#{slug}"
    end
  end

  defmodule Widget do
    alias Carrier.Data.Source.Redash.Query

    defstruct [:id, :query]

    def new(%{"id" => id} = params) do
      %__MODULE__{
        id: id |> to_string(),
        query:
          params["visualization"] |> Nillable.map(fn %{"query" => query} -> Query.new(query) end)
      }
    end
  end

  defmodule Query do
    alias Carrier.Data.Source.Redash.Parameter

    defstruct [:id, :parameters]

    def new(%{"id" => id} = params) do
      %__MODULE__{
        id: id |> to_string(),
        parameters:
          (params |> get_in(["options", "parameters"]) || []) |> Enum.map(&Parameter.new/1)
      }
    end
  end

  defmodule Parameter do
    defstruct [:name, :type, :value]

    def new(%{"name" => name, "type" => type, "value" => value}) do
      %__MODULE__{name: name, type: type, value: value}
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
        %{
          data_source_info: %{params: %{dashboards: dashboard_params}},
          datetime: utc_datetime,
          timezone: timezone
        },
        %DataSource{source: :redash} = data_source
      ) do
    credentials = DataSource.to_credentials(data_source)

    with dashboard_ids = dashboard_params |> Enum.map(& &1.id),
         {:ok, dashboards} <- dashboard_ids |> do_list_dashboards_async(credentials),
         {:ok, _} <- dashboards |> do_refresh_dashboards(utc_datetime, timezone, credentials),
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

  @impl true
  def data_to_threads(_params, %DataSource{source: :redash} = data_source, %{
        dashboards: dashboards,
        dashboard_image_urls: dashboard_image_urls
      }) do
    %{host: host} = DataSource.to_credentials(data_source)

    threads =
      [dashboards, dashboard_image_urls]
      |> Enum.zip_with(fn [%Dashboard{name: name} = dashboard, dashboard_image_url] ->
        [
          Block.link(name, Dashboard.url(dashboard, host)),
          Block.image(name, dashboard_image_url, name),
          Block.button("Open Original Image", dashboard_image_url)
        ]
      end)

    {:ok, threads}
  end

  def list_dashboards(%DataSource{source: :redash} = data_source) do
    credentials = data_source |> DataSource.to_credentials()

    with {:ok, dashboards} <- do_list_dashboards(credentials) do
      dashboards =
        dashboards
        |> Enum.filter(&(&1.is_draft == false and &1.is_archived == false))

      {:ok, dashboards}
    end
  end

  def get_dashboard_image_binary(%DataSource{source: :redash} = data_source, dashboard_id) do
    credentials = data_source |> DataSource.to_credentials()

    with {:ok, %Dashboard{public_url: public_url}} when not is_nil(public_url) <-
           RedashAPI.get_dashboard(dashboard_id, credentials),
         {:ok, image_binary} <- RedashAPI.get_dashboard_screenshot(public_url) do
      {:ok, image_binary}
    else
      # TODO: change error message
      {:ok, %Dashboard{public_url: nil}} -> {:error, "Dashboard public URL 을 설정 후 다시 시도해주세요"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_list_dashboards(credentials) do
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

  defp do_refresh_dashboards(dashboards, utc_datetime, timezone, credentials) do
    dashboards
    |> Async.map(fn dashboard ->
      refresh_dashboard(dashboard, utc_datetime, timezone, credentials)
    end)
    |> Async.unwrap_map_ok_results()
  end

  defp do_list_dashboard_image_binaries_async(dashboards) do
    dashboards
    |> Async.map(fn dashboard -> RedashAPI.get_dashboard_screenshot(dashboard.public_url) end)
    |> Async.unwrap_map_ok_results()
  end

  # https://github.com/getredash/redash-toolbelt/blob/master/redash_toolbelt/examples/refresh_dashboard.py

  defp refresh_dashboard(%Dashboard{widgets: widgets}, utc_datetime, timezone, credentials) do
    # load queries in dashboard
    {:ok, queries} =
      widgets
      |> Enum.filter(&(&1.query != nil))
      |> Enum.map(& &1.query.id)
      |> do_list_queries_async(credentials)

    # refresh queries
    queries
    |> Async.map(fn %Query{id: query_id, parameters: parameters} ->
      parameters_param =
        parameters
        |> Enum.map(&{&1.name, RedashAPI.Parameter.generate_value(&1, utc_datetime, timezone)})
        |> Map.new()

      params = %{
        parameters: parameters_param
      }

      RedashAPI.run_query(query_id, params, credentials)
    end)
    |> Async.unwrap_map_ok_results()
    |> IO.inspect()
  end

  defp do_list_queries_async(query_ids, credentials) do
    query_ids
    |> Async.map(fn query_id -> RedashAPI.get_query(query_id, credentials) end)
    |> Async.unwrap_map_ok_results()
  end
end
