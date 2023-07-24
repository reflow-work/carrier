defmodule Carrier.Roles.SuperTest do
  use Carrier.DataCase, async: true
  use Carrier.Roles

  describe "fetch_role_by_name/1" do
    setup do
      role = Factory.insert(:role)

      %{role: role}
    end

    test "with valid params", %{role: role} do
      assert {:ok, %Role{} = fetched_role} = Roles.Super.fetch_role_by_name(role.name)
      assert same_records?(fetched_role, role)
    end

    test "with invalid role_name" do
      assert {:error, {:resource_not_found, %{target: Role}}} =
               Roles.Super.fetch_role_by_name("invalid")
    end

    test "with deleted role_name", %{role: role} do
      role |> soft_delete!()

      assert {:error, {:resource_not_found, %{target: Role}}} =
               Roles.Super.fetch_role_by_name(role.name)
    end
  end
end
