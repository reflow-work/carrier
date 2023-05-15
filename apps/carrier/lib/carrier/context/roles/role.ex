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
      },
      %{
        name: "Trial Plan",
        permissions: [
          "data-source.tableau",
          "reports.max-count.infinite"
        ]
      },
      %{
        name: "Basic Plan",
        permissions: [
          "reports.max-count.50"
        ]
      },
      %{
        name: "Pro Plan",
        permissions: [
          "data-source.tableau",
          "reports.max-count.infinite"
        ]
      }
    ]
  end

  def fetch_by_name(role_name) do
    __MODULE__
    |> where([r], r.name == ^role_name)
    |> where([p], is_nil(p.deleted_at))
  end
end
