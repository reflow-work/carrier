defmodule Carrier.Roles.Super do
  use Carrier.Roles
  alias Carrier.TenantRepo

  def fetch_role_with_name(role_name) do
    Role.fetch_with_name(role_name)
    |> TenantRepo.one(skip_org_id: true)
    |> case do
      %Role{} = role ->
        {:ok, role}

      nil ->
        {:error, {:resource_not_found, %{target: Role, conditions: %{role_name: role_name}}}}
    end
  end
end
