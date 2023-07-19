defmodule Carrier.Accounts.SuperTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.{Org, User}

  @moduletag repo: TenantRepo

  describe "auth/2" do
    setup do
      admin_role = TenantFactory.insert(:role, name: "Admin")
      member_role = TenantFactory.insert(:role, name: "Member")

      %{admin_role: admin_role, member_role: member_role}
    end

    test "with already signed up user" do
      user = TenantFactory.insert(:user)

      assert {:ok, {:signed_in, signed_in_user}} = Accounts.Super.auth(user.email, nil)
      assert same_records?(signed_in_user, user)
    end

    test "with not signed up user, without org_id", %{admin_role: admin_role} do
      email = "json@reflow.work"

      assert {:ok, {:signed_up, signed_up_user}} = Accounts.Super.auth(email, nil)
      assert signed_up_user.email == email
      assert signed_up_user.org_id != nil
      assert signed_up_user.role_id == admin_role.id
    end

    test "with not signed up user, with org_id", %{member_role: member_role} do
      org = TenantFactory.insert(:org)
      email = "json@reflow.work"

      assert {:ok, {:signed_up, signed_up_user}} = Accounts.Super.auth(email, org.org_id)
      assert signed_up_user.org_id == org.org_id
      assert signed_up_user.role_id == member_role.id
    end
  end

  describe "create_org/1" do
    test "with valid attrs" do
      params = %{
        name: "organization"
      }

      assert {:ok, %Org{} = created_org} = Accounts.Super.create_org(params)
      assert same_fields?(created_org, params, [:name])
    end
  end

  describe "fetch_user_by_email/1" do
    setup do
      user = TenantFactory.insert(:user)

      %{user: user}
    end

    test "with valid email", %{user: user} do
      assert {:ok, %User{} = fetched_user} = Accounts.Super.fetch_user_by_email(user.email)

      assert same_records?(fetched_user, user)
    end

    test "with invalid email" do
      assert {:error, {:resource_not_found, %{target: User}}} =
               Accounts.Super.fetch_user_by_email("invalid_email")
    end

    test "with deleted user email", %{user: user} do
      user |> soft_delete!()

      assert {:error, {:resource_not_found, %{target: User}}} =
               Accounts.Super.fetch_user_by_email("invalid_email")
    end
  end

  describe "sign_up/1" do
    setup do
      org = TenantFactory.insert(:org)
      role = TenantFactory.insert(:role)

      %{org: org, role: role}
    end

    test "with valid attrs", %{org: org, role: role} do
      params = %{
        org_id: org.org_id,
        email: "json@reflow.work",
        role_id: role.id
      }

      assert {:ok, %User{} = created_user} = Accounts.Super.signup(params)
      assert same_fields?(created_user, params, [:org_id, :email, :role_id])
    end

    test "with duplicated email", %{org: org, role: role} do
      email = "json@reflow.work"

      TenantFactory.insert(:user, org: org, email: email, role: role)

      params = %{
        org_id: org.org_id,
        email: email,
        role_id: role.id
      }

      assert {:error, _} = Accounts.Super.signup(params)
    end
  end

  describe "postload_role/1" do
    setup do
      user = TenantFactory.insert(:user)

      Tenant.put_org_id(user.org_id)

      %{user: user}
    end

    test "test", %{user: user} do
      user_without_role = reload!(user)
      user_with_role = user_without_role |> Accounts.Super.postload_role()

      assert same_records?(user_with_role.role, user.role)
    end
  end

  describe "get_org/1" do
    setup do
      org = TenantFactory.insert(:org)

      %{org: org}
    end

    test "test", %{org: org} do
      {:ok, fetched_org} = org.org_id |> Accounts.Super.get_org()

      assert same_records?(fetched_org, org)
    end
  end
end
