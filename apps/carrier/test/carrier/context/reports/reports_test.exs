defmodule Carrier.ReportsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Reports

  @moduletag repo: TenantRepo

  describe "create_report/1" do
    setup do
      org = TenantFactory.insert(:org)

      %{org: org}
    end

    test "with valid attrs", %{org: org} do
      params = %{
        org_id: org.org_id,
        name: "Daily Report",
        trigger_time: ~T[10:00:00],
        integration_info: %{
          "integration_id" => 1,
          "channel_id" => "channel_id"
        },
        data_source_info: %{
          "data_source_id" => 1,
          "sql_template" => "sql",
          "timezone" => "Asia/Seoul",
          "period" => 28,
          "window_size" => 7,
          "comparing_period" => 7,
          "columns" => ["total_revenue"]
        }
      }

      assert {:ok, created_report} = Reports.create_report(params)
      assert same_fields?(created_report, params, [:org_id, :name, :trigger_time])
    end
  end

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
