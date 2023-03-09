defmodule Carrier.OpsTest do
  use Carrier.DataCase, async: true
  use Carrier.Accounts
  alias Carrier.Ops

  describe "delete_org/2" do
    @describetag repo: TenantRepo

    setup do
      org = TenantFactory.insert(:org)
      other_org = TenantFactory.insert(:org)

      TenantFactory.insert(:user, org_id: org.org_id)
      TenantFactory.insert(:user, org_id: other_org.org_id)

      %{org: org, other_org: other_org}
    end

    test "with valid params", %{org: org, other_org: other_org} do
      assert {:ok, deleted_org} = Ops.delete_org(org.org_id, org.name)
      assert same_records?(deleted_org, org)

      TenantRepo.put_org_id(org.org_id)
      assert [%Org{deleted_at: deleted_at}] = TenantRepo.all(Org)
      assert deleted_at != nil
      assert [%User{deleted_at: deleted_at}] = TenantRepo.all(User)
      assert deleted_at != nil

      TenantRepo.put_org_id(other_org.org_id)
      assert [%Org{deleted_at: nil}] = TenantRepo.all(Org)
      assert [%User{deleted_at: nil}] = TenantRepo.all(User)
    end

    test "with invalid name", %{org: org} do
      assert {:error, :invalid_org} = Ops.delete_org(org.org_id, "invalid name")
    end
  end

  describe "hard_delete_org/2" do
    @describetag repos: [Repo, TenantRepo]

    setup do
      org = TenantFactory.insert(:org)
      other_org = TenantFactory.insert(:org)

      TenantFactory.insert(:user, org_id: org.org_id)
      TenantFactory.insert(:user, org_id: other_org.org_id)

      %{org: org, other_org: other_org}
    end

    test "with valid params", %{org: org, other_org: other_org} do
      assert {:ok, deleted_org} = Ops.hard_delete_org(org.org_id, org.name)
      assert same_records?(deleted_org, org)

      TenantRepo.put_org_id(org.org_id)
      assert [] = TenantRepo.all(Org)
      assert [] = TenantRepo.all(User)

      TenantRepo.put_org_id(other_org.org_id)
      assert [_] = TenantRepo.all(Org)
      assert [_] = TenantRepo.all(User)
    end

    test "with invalid name", %{org: org} do
      assert {:error, :invalid_org} = Ops.hard_delete_org(org.org_id, "invalid name")
    end
  end
end
