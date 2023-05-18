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
          "reports.max-count.infinity"
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
          "reports.max-count.infinity"
        ]
      }
    ]
  end

  def fetch_by_name(role_name) do
    __MODULE__
    |> where([r], r.name == ^role_name)
    |> where_not_deleted()
  end

  def report_max_count(role) do
    report_max_count_permission =
      role.permissions |> Enum.find(fn x -> x |> String.contains?("reports.max-count") end)

    case report_max_count_permission do
      nil ->
        0

      "reports.max-count." <> max_count_str ->
        case max_count_str do
          "infinity" -> :infinity
          _ -> max_count_str |> String.to_integer()
        end
    end
  end
end
