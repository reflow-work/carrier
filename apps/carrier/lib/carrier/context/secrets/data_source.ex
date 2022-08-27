defmodule Carrier.Secrets.DataSource do
  use Carrier.Schema

  schema "data_sources" do
    field :org_id, :id
    field :source, Ecto.Enum, values: [:postgres, :mysql]
    field :conn_info_id, :id
  end
end
