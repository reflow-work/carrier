defmodule Carrier.AccountsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Accounts
  alias Carrier.Accounts.User

  @moduletag repo: TenantRepo

  describe "fetch_user/1" do
    setup do
      user = TenantFactory.insert(:user)

      TenantRepo.put_org_id(user.org_id)

      {:ok, %{user: user}}
    end

    test "with valid user_id", %{user: user} do
      assert {:ok, %User{} = fetched_user} = Accounts.fetch_user(user.id)

      assert same_records?(fetched_user, user)
    end
  end

  describe "update_user/2" do
    setup do
      user = TenantFactory.insert(:user)

      TenantRepo.put_org_id(user.org_id)

      {:ok, %{user: user}}
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
