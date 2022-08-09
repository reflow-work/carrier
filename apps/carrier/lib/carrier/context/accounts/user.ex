defmodule Carrier.Accounts.User do
  use Carrier.Schema

  schema "users" do
    field :org_id, :integer
    field :email, :string
  end
end
