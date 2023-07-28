defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source

  use Carrier.Integrations
  alias Carrier.External.RedashAPI

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

  def list_dashboards(%DataSource{source: :redash} = data_source) do
    credentials = data_source |> DataSource.to_credentials()

    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok,
         %{dashboards: dashboards, pagination: %Pagination{page: page, page_size: page_size, total: total}}} =
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
end
