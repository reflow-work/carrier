defmodule Carrier.ReportsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Reports

  @moduletag repo: TenantRepo

  describe "list_reports/0" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report = TenantFactory.insert(:report, org_id: org.org_id)
      TenantFactory.insert(:report, org_id: org.org_id, deleted_at: DateTime.utc_now())
      TenantFactory.insert(:report)

      %{reports: [report]}
    end

    test "with valid params", %{reports: [report]} do
      assert {:ok, [fetched_report]} = Reports.list_reports()
      assert same_records?(fetched_report, report)
    end
  end

  describe "fetch_report/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report = TenantFactory.insert(:report, org_id: org.org_id)

      %{report: report}
    end

    test "with report_id", %{report: report} do
      assert {:ok, fetched_report} = Reports.fetch_report(report.id)
      assert same_records?(fetched_report, report)
    end
  end

  describe "delete_report/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report = TenantFactory.insert(:report, org_id: org.org_id)

      %{report: report}
    end

    test "with report_id", %{report: report} do
      assert {:ok, deleted_report} = Reports.delete_report(report.id)
      assert same_records?(deleted_report, report)
      assert deleted_report.deleted_at != nil
    end
  end
end
