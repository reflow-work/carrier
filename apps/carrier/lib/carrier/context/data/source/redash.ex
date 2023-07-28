defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source

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
    case RedashAPI.list_dashboards(credentials) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:invalid_conn_info, reason}}
    end
  end
end
