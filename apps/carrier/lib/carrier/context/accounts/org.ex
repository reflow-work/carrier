defmodule Carrier.Accounts.Org do
  use Ecto.Schema

  @primary_key {:org_id, :id, autogenerate: true}
  schema "orgs" do
    field :name, :string
  end
end
