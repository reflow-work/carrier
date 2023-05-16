defmodule Carrier.Roles.Role do
  use Carrier.Schema

  schema "roles" do
    field :name, :string
    field :permissions, {:array, :string}

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  def default_roles() do
    [
      %{
        name: "Admin",
        permissions: [
          "billing.payment.manage"
        ]
      },
      %{
        name: "Member",
        permissions: []
      }
    ]
  end

  def fetch_by_name(role_name) do
    __MODULE__
    |> where([r], r.name == ^role_name)
    |> where_not_deleted()
  end
end
