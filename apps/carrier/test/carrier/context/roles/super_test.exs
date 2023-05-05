defmodule Carrier.Roles.SuperTest do
  use Carrier.DataCase, async: true
  use Carrier.Roles

  @moduletag repo: TenantRepo

  describe "fetch_role_with_name/1" do
    setup do
      role = TenantFactory.insert(:role)

      %{role: role}
    end

    test "with valid params", %{role: role} do
      assert {:ok, %Role{} = fetched_role} = Roles.Super.fetch_role_with_name(role.name)
      assert same_records?(fetched_role, role)
    end

    test "with invalid role_name" do
      assert {:error, {:resource_not_found, %{target: Role}}} =
               Roles.Super.fetch_role_with_name("invalid")
    end

    test "with deleted role_name", %{role: role} do
      role |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now()}) |> TenantRepo.update!()

      assert {:error, {:resource_not_found, %{target: Role}}} =
               Roles.Super.fetch_role_with_name(role.name)
    end
  end
end
