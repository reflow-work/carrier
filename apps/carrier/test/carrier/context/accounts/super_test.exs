defmodule Carrier.Accounts.SuperTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.{Org, User}

  @moduletag repo: TenantRepo

  describe "auth/1" do
    test "with already signed up user" do
      user = TenantFactory.insert(:user)

      assert {:ok, {:signed_in, signed_in_user}} = Accounts.Super.auth(user.email)
      assert same_records?(signed_in_user, user)
    end

    test "with not signed up user" do
      email = "json@reflow.work"

      assert {:ok, {:signed_up, signed_up_user}} = Accounts.Super.auth(email)
      assert signed_up_user.email == email
      assert signed_up_user.org_id != nil
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
      user |> Ecto.Changeset.change(deleted_at: DateTime.utc_now()) |> TenantRepo.update!()

      assert {:error, {:resource_not_found, %{target: User}}} =
               Accounts.Super.fetch_user_by_email("invalid_email")
    end
  end

  describe "sign_up/1" do
    setup do
      org = TenantFactory.insert(:org)

      %{org: org}
    end

    test "with valid attrs", %{org: org} do
      params = %{
        org_id: org.org_id,
        email: "json@reflow.work"
      }

      assert {:ok, %User{} = created_user} = Accounts.Super.signup(params)
      assert same_fields?(created_user, params, [:org_id, :email])
    end

    test "with duplicated email", %{org: org} do
      email = "json@reflow.work"

      TenantFactory.insert(:user, org: org, email: email)

      params = %{
        org_id: org.org_id,
        email: email
      }

      assert {:error, _} = Accounts.Super.signup(params)
    end
  end
end
