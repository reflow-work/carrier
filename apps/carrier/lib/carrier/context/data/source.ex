defmodule Carrier.Data.Source do
  alias Carrier.Data.Source

  def get_module(source) do
    case source do
      :postgres -> Source.Postgres
      :mysql -> Source.MySQL
    end
  end
end
