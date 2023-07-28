defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source

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
  def validate_conn(:redash, _credentials, _opts) do
    :ok
  end
end
