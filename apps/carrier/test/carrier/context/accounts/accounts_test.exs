defmodule Carrier.AccountsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.{Org, User}

  @moduletag repo: TenantRepo

  describe "update_org/1" do
    setup do
      org = TenantFactory.insert(:org)
      Tenant.put_org_id(org.org_id)

      %{org: org}
    end

    test "with valid attrs", %{org: org} do
      params = %{
        name: "org1",
        industry: "IT Service",
        employee_count: "10-19"
      }

      assert {:ok, %Org{} = updated_org} = Accounts.update_org(params)

      assert same_records?(updated_org, org)
      assert same_fields?(updated_org, params, [:name, :industry, :employee_count])
      assert updated_org.onboarded == true
    end
  end

  describe "fetch_user/1" do
    setup do
      role = TenantFactory.insert(:role)
      user = TenantFactory.insert(:user, role: role)

      Tenant.put_org_id(user.org_id)

      %{user: user, role: role}
    end

    test "with valid user_id", %{user: user, role: role} do
      assert {:ok, %User{} = fetched_user} = Accounts.fetch_user(user.id)

      assert same_records?(fetched_user, user)
      assert same_records?(fetched_user.org, user.org)
      assert same_records?(fetched_user.role, role)
    end

    test "with deleted user_id", %{user: user} do
      user |> soft_delete!()

      assert {:error, {:resource_not_found, _}} = Accounts.fetch_user(user.id)
    end
  end

  describe "fetch_billing_user/1" do
    setup do
      admin_role = TenantFactory.insert(:role, name: "Admin")
      admin_user = TenantFactory.insert(:user, role: admin_role)
      _another_user_of_same_org = TenantFactory.insert(:user, org: admin_user.org)
      _user_of_another_org = TenantFactory.insert(:user)

      Tenant.put_org_id(admin_user.org_id)

      %{admin_user: admin_user}
    end

    test "test", %{admin_user: admin_user} do
      assert {:ok, %User{} = fetched_billing_user} = Accounts.fetch_billing_user()

      assert same_records?(fetched_billing_user, admin_user)
    end
  end

  describe "update_user/2" do
    setup do
      user = TenantFactory.insert(:user)

      Tenant.put_org_id(user.org_id)

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

  describe "list_users/0" do
    setup do
      user1 = TenantFactory.insert(:user)
      user2 = TenantFactory.insert(:user, org: user1.org)
      _user_of_another_org = TenantFactory.insert(:user)

      Tenant.put_org_id(user1.org_id)

      %{user1: user1, user2: user2}
    end

    test "test", %{user1: user1, user2: user2} do
      assert {:ok, [fetched_user1, fetched_user2]} = Accounts.list_users()

      assert same_records?(fetched_user1, user1)
      assert same_records?(fetched_user2, user2)
    end
  end
end
