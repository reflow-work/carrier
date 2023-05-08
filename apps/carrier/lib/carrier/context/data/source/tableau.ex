defmodule Carrier.Data.Source.Tableau do
  @behaviour Carrier.Data.Source

  use Carrier.Integrations
  alias Carrier.External.TableauAPI
  alias Carrier.Core.{Async, Traversable, OkTuple}

  ### behaviors

  @impl true
  def load_raw_data(%DataSource{source: :tableau, conn_info: %ConnInfo{} = conn_info}, %{
        views: views
      }) do
    views
    |> Enum.map(& &1.id)
    |> list_view_image_binary_async(ConnInfo.to_credentials(conn_info))
  end

  # TODO: implement it
  @impl true
  def transform_data(%DataSource{source: :tableau}, raw_data) do
    data =
      raw_data
      |> Enum.map(& &1)

    {:ok, data}
  end

  # TODO: implement it
  @impl true
  def data_to_blocks(%DataSource{source: :tableau}, data) do
    blocks =
      data
      |> Enum.map(& &1)

    {:ok, blocks}
  end

  ### raw functions

  defmodule Pagination do
    defstruct [:page, :page_size, :total]

    def new(%{
          "pageNumber" => page_str,
          "pageSize" => page_size_str,
          "totalAvailable" => total_str
        }) do
      %__MODULE__{
        page: String.to_integer(page_str),
        page_size: String.to_integer(page_size_str),
        total: String.to_integer(total_str)
      }
    end
  end

  defmodule View do
    defstruct [:id, :name, :full_name]

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "Project"},
          "project" => %{"name" => project_name},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "#{project_name} / #{workbook_name} / #{name}"}
    end

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "PersonalSpace"},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "Personal Space / #{workbook_name} / #{name}"}
    end
  end

  def signin(%{host: host, email: email, password: password, site: site}) do
    TableauAPI.signin(%{host: host, name: email, password: password, site: site})
  end

  def list_views(%{host: host} = conn_info) do
    with {:ok, %{token: token, site_id: site_id}} <- signin(conn_info),
         {:ok, views} <- do_list_views(%{host: host, site_id: site_id, token: token}) do
      {:ok, views}
    end
  end

  def list_view_image_binary_async(view_ids, %{host: host} = conn_info) do
    with {:ok, %{token: token, site_id: site_id}} <- signin(conn_info),
         {:ok, results} <-
           view_ids
           |> Async.map(fn view_id ->
             do_get_view_image_binary(view_id, %{host: host, site_id: site_id, token: token})
           end)
           |> Traversable.traverse_all()
           |> OkTuple.map(&Traversable.traverse_all/1) do
      {:ok, results}
    end
  end

  def get_view_image_binary(view_id, %{host: host} = conn_info) do
    with {:ok, %{token: token, site_id: site_id}} <- signin(conn_info),
         {:ok, view_image_binary} <-
           do_get_view_image_binary(view_id, %{host: host, site_id: site_id, token: token}) do
      {:ok, view_image_binary}
    end
  end

  defp do_get_view_image_binary(view_id, %{host: host, site_id: site_id, token: token}) do
    TableauAPI.query_view_image(%{
      host: host,
      site_id: site_id,
      view_id: view_id,
      token: token
    })
  end

  defp do_list_views(%{host: host, site_id: site_id, token: token}) do
    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok,
         %{views: views, pagination: %Pagination{page: page, page_size: page_size, total: total}}} =
          TableauAPI.query_views_for_site(%{
            host: host,
            site_id: site_id,
            page: page,
            token: token
          })

        last_page = div(total, page_size) + 1

        case last_page == page do
          true -> {views, nil}
          false -> {views, page + 1}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end
end
