defmodule Carrier.AccountsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.User

  @moduletag repo: TenantRepo

  describe "postload_role/1" do
    setup do
      role = TenantFactory.insert(:role)
      user = TenantFactory.insert(:user, role_id: role.id)

      TenantRepo.put_org_id(user.org_id)

      %{user: user, role: role}
    end

    test "test", %{user: user, role: role} do
      user_with_role = user |> Accounts.postload_role()

      assert same_records?(user_with_role.role, role)
    end
  end

  describe "fetch_user/1" do
    setup do
      role = TenantFactory.insert(:role)
      user = TenantFactory.insert(:user, role: role)

      TenantRepo.put_org_id(user.org_id)

      %{user: user, role: role}
    end

    test "with valid user_id", %{user: user, role: role} do
      assert {:ok, %User{} = fetched_user} = Accounts.fetch_user(user.id)

      assert same_records?(fetched_user, user)
      assert same_records?(fetched_user.org, user.org)
      assert same_records?(fetched_user.role, role)
    end

    test "with deleted user_id", %{user: user} do
      user |> Ecto.Changeset.change(deleted_at: DateTime.utc_now()) |> TenantRepo.update!()

      assert {:error, {:resource_not_found, _}} = Accounts.fetch_user(user.id)
    end
  end

  describe "fetch_billing_user/0" do
    setup do
      user = TenantFactory.insert(:user)
      _user_of_another_org = TenantFactory.insert(:user)

      TenantRepo.put_org_id(user.org_id)

      %{user: user}
    end

    test "test", %{user: user} do
      assert {:ok, %User{} = fetched_billing_user} = Accounts.fetch_billing_user()

      assert same_records?(fetched_billing_user, user)
    end
  end

  describe "update_user/2" do
    setup do
      user = TenantFactory.insert(:user)

      TenantRepo.put_org_id(user.org_id)

      %{user: user}
    end

    test "with valid user_id and attrs", %{user: user} do
      now = DateTime.utc_now()

      attrs = %{
        position: "CEO/대표",
        agreed_privacy_policy_at: now,
        agreed_terms_of_service_at: now
      }

      assert {:ok, %User{} = updated_user} = Accounts.update_user(user.id, attrs)

      assert same_fields?(updated_user, attrs, [:position])
    end
  end
end
