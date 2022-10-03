defmodule Carrier.ReportsTest do
  use Carrier.DataCase, async: true
  use Oban.Testing, repo: TenantRepo
  alias Carrier.Reports
  alias Carrier.Reports.{Report, ReportLog}

  @moduletag repo: TenantRepo

  describe "create_report/1" do
    setup do
      org = TenantFactory.insert(:org)
      integration = TenantFactory.insert(:integration, org_id: org.org_id)
      data_source = TenantFactory.insert(:data_source, org_id: org.org_id, source: :postgres)

      %{org: org, integration: integration, data_source: data_source}
    end

    test "with valid attrs", %{org: org, integration: integration, data_source: data_source} do
      params = %{
        org_id: org.org_id,
        name: "Daily Report",
        trigger_time: ~T[10:00:00],
        integration_info: %{
          "integration_id" => integration.id,
          "channel_id" => "channel_id",
          "channel_name" => "channel_name"
        },
        data_source_info: %{
          "data_source_id" => data_source.id,
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

      # ReportJob

      TenantRepo.set_skip_org_id()

      assert [%{scheduled_at: scheduled_at}] = all_enqueued(worker: Carrier.Works.ReportJob)
      assert scheduled_at |> DateTime.to_time() |> Time.compare(~T[10:00:00]) == :eq

      # ReportLog

      report_log = TenantRepo.get_by(ReportLog, report_id: created_report.id)

      assert report_log.org_id == created_report.org_id
      assert report_log.report_id == created_report.id
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

      %{org: org, report: report}
    end

    test "with report_id", %{report: report} do
      assert {:ok, fetched_report} = Reports.fetch_report(report.id)
      assert same_records?(fetched_report, report)
    end

    test "with invalid report_id" do
      assert {:error, {:resource_not_found, %{target: Report}}} = Reports.fetch_report(0)
    end

    test "with deleted report_id", %{org: org} do
      deleted_report =
        TenantFactory.insert(:report, org_id: org.org_id, deleted_at: DateTime.utc_now())

      assert {:error, {:resource_not_found, %{target: Report}}} =
               Reports.fetch_report(deleted_report.id)
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

      assert %{deleted_at: deleted_at} = TenantRepo.get_by(Report, id: report.id)
      assert deleted_at != nil
    end
  end

  describe "record_scheduled_report_log/1" do
    setup do
      report = TenantFactory.insert(:report)

      %{report: report}
    end

    test "with valid attrs", %{report: report} do
      params = %{
        org_id: report.org_id,
        report_id: report.id
      }

      assert {:ok, scheduled_report_log} = Reports.record_scheduled_report_log(params)
      assert same_fields?(scheduled_report_log, params, [:org_id, :report_id])
      assert scheduled_report_log.status == :scheduled
      assert scheduled_report_log.scheduled_at != nil
    end
  end

  describe "record_succeeded_report_log/1" do
    setup do
      report_log = TenantFactory.insert(:report_log)

      %{report_log: report_log}
    end

    test "with valid attrs", %{report_log: report_log} do
      assert {:ok, updated_report_log} = Reports.record_succeeded_report_log(report_log)
      assert updated_report_log.sent_at != nil
    end
  end

  describe "record_failed_report_log/1" do
    setup do
      report_log = TenantFactory.insert(:report_log)

      %{report_log: report_log}
    end

    test "with valid attrs", %{report_log: report_log} do
      error_message = "error~"

      assert {:ok, updated_report_log} =
               Reports.record_failed_report_log(report_log, %{error_message: error_message})

      assert updated_report_log.error_message == error_message
    end
  end
end
