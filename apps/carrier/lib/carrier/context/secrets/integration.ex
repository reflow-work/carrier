defmodule Carrier.Secrets.Integration do
  use Carrier.Schema

  schema "integrations" do
    field :org_id, :integer
    field :service_name, Ecto.Enum, values: [:slack]
    field :conn_info_id, :integer
  end
end
