defmodule Carrier.ReportsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Reports

  @moduletag repo: TenantRepo

  describe "list_reports/0" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report = TenantFactory.insert(:report, org_id: org.org_id)
      TenantFactory.insert(:report)

      %{reports: [report]}
    end

    test "with valid params", %{reports: [report]} do
      assert {:ok, [fetched_report]} = Reports.list_reports()
      assert same_records?(fetched_report, report)
    end
  end
end
