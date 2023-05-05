defmodule Carrier.Roles.Role do
  use Carrier.Schema

  schema "roles" do
    field :name, :string
    field :permissions, {:array, :string}

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  def fetch_by_name(role_name) do
    __MODULE__
    |> where([r], r.name == ^role_name)
    |> where([p], is_nil(p.deleted_at))
  end
end
