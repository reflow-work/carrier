defmodule Carrier.OpsTest do
  use Carrier.DataCase, async: true
  use Carrier.Accounts
  alias Carrier.Ops

  describe "delete_org/2" do
    setup do
      org = Factory.insert(:org)
      other_org = Factory.insert(:org)

      Factory.insert(:user, org: org)
      Factory.insert(:user, org: other_org)

      %{org: org, other_org: other_org}
    end

    test "with valid params", %{org: org, other_org: other_org} do
      assert {:ok, deleted_org} = Ops.delete_org(org.org_id, org.name)
      assert same_records?(deleted_org, org)

      Tenant.put_org_id(org.org_id)
      assert [%Org{deleted_at: deleted_at}] = Repo.all(Org)
      assert deleted_at != nil
      assert [%User{deleted_at: deleted_at}] = Repo.all(User)
      assert deleted_at != nil

      Tenant.put_org_id(other_org.org_id)
      assert [%Org{deleted_at: nil}] = Repo.all(Org)
      assert [%User{deleted_at: nil}] = Repo.all(User)
    end

    test "with invalid name", %{org: org} do
      assert {:error, :invalid_org} = Ops.delete_org(org.org_id, "invalid name")
    end
  end

  describe "hard_delete_org/2" do
    @describetag repos: [Repo, Repo]

    setup do
      org = Factory.insert(:org)
      other_org = Factory.insert(:org)

      Factory.insert(:user, org: org)
      Factory.insert(:user, org: other_org)

      %{org: org, other_org: other_org}
    end

    test "with valid params", %{org: org, other_org: other_org} do
      assert {:ok, deleted_org} = Ops.hard_delete_org(org.org_id, org.name)
      assert same_records?(deleted_org, org)

      Tenant.put_org_id(org.org_id)
      assert [] = Repo.all(Org)
      assert [] = Repo.all(User)

      Tenant.put_org_id(other_org.org_id)
      assert [_] = Repo.all(Org)
      assert [_] = Repo.all(User)
    end

    test "with invalid name", %{org: org} do
      assert {:error, :invalid_org} = Ops.hard_delete_org(org.org_id, "invalid name")
    end
  end
end
