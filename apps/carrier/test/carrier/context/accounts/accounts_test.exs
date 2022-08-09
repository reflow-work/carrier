defmodule Carrier.AccountsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.User

  @moduletag repo: Repo

  describe "fetch_user_by_email/1" do
    setup do
      user = Factory.insert(:user)

      %{user: user}
    end

    test "with valid email", %{user: user} do
      assert {:ok, %User{} = fetched_user} = Accounts.fetch_user_by_email(user.email)

      assert same_records?(fetched_user, user)
    end

    test "with invalid email" do
      assert {:error, {:resource_not_found, _}} = Accounts.fetch_user_by_email("invalid_email")
    end
  end

  describe "sign_up/1" do
    setup do
      org = Factory.insert(:org)

      %{org: org}
    end

    test "with valid attrs", %{org: org} do
      params = %{
        org_id: org.org_id,
        email: "json@reflow.work"
      }

      assert {:ok, %User{} = created_user} = Accounts.signup(params)
      assert same_fields?(created_user, params, [:org_id, :email])
    end

    test "with duplicated email", %{org: org} do
      params = %{
        org_id: org.org_id,
        email: "json@reflow.work"
      }

      Factory.insert(:user, params)

      assert {:error, _} = Accounts.signup(params)
    end
  end
end
