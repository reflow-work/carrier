defmodule Carrier.Roles.Super do
  use Carrier.Roles
  alias Carrier.TenantRepo

  def fetch_role_by_name(role_name) do
    Role.fetch_by_name(role_name)
    |> TenantRepo.one(org_id: :skip)
    |> case do
      %Role{} = role ->
        {:ok, role}

      nil ->
        {:error, {:resource_not_found, %{target: Role, conditions: %{role_name: role_name}}}}
    end
  end
end
