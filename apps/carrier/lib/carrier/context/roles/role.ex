defmodule Carrier.Roles.Role do
  use Ecto.Schema

  schema "roles" do
    field :name, :string
    field :permissions, {:array, :string}

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end
end
