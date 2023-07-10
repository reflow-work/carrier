defmodule Carrier.ReportsTest do
  use Carrier.DataCase, async: true
  use Carrier.Reports
  use Oban.Testing, repo: Carrier.TenantRepo
  alias Carrier.TenantFactory
  alias Carrier.TenantRepo
  alias Carrier.Core.DateTimeHelper

  @moduletag repo: TenantRepo

  describe "fetch_report_info/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report_info = TenantFactory.insert(:report_info, org_id: org.org_id)

      %{org: org, report_info: report_info}
    end

    test "with valid report_info_id", %{report_info: report_info} do
      assert {:ok, fetched_report_info} = Reports.fetch_report_info(report_info.id)
      assert same_records?(fetched_report_info, report_info)
    end

    test "with deleted report_info_id", %{org: org} do
      deleted_report_info =
        TenantFactory.insert(:report_info, org_id: org.org_id, deleted_at: DateTime.utc_now())

      assert {:error, {:resource_not_found, _}} =
               Reports.fetch_report_info(deleted_report_info.id)
    end
  end

  describe "create_report/1" do
    setup do
      org = TenantFactory.insert(:org)
      user = TenantFactory.insert(:user, org: org)
      data_target = TenantFactory.insert(:data_target, org_id: org.org_id)
      data_source = TenantFactory.insert(:data_source, org_id: org.org_id, source: :postgres)

      %{org: org, user: user, data_target: data_target, data_source: data_source}
    end

    test "with valid attrs", %{
      org: org,
      user: user,
      data_target: data_target,
      data_source: data_source
    } do
      params = %{
        org_id: org.org_id,
        user_id: user.id,
        name: "Daily Report",
        interval: :daily,
        trigger_time: ~T[10:00:00],
        timezone: "Asia/Seoul",
        data_target_info: %{
          data_target_id: data_target.id,
          target: :slack,
          params: %{
            channel_id: "channel_id",
            channel_name: "channel_name",
            channel_type: "public_channel"
          }
        },
        data_source_info: %{
          data_source_id: data_source.id,
          source: :postgres,
          sql_template: "sql",
          timezone: "Asia/Seoul",
          period: 28,
          window_size: 7,
          comparing_period: 7,
          columns: ["total_revenue"]
        }
      }

      assert {:ok, created_report} = Reports.create_report(params)

      assert same_fields?(created_report, params, [
               :org_id,
               :user_id,
               :name,
               :interval,
               :trigger_time,
               :timezone
             ])

      assert %DataTargetInfo{params: data_target_info_params} = created_report.data_target_info
      assert %{} = data_target_info_params

      TenantRepo.set_skip_org_id()

      # ReportInfo

      assert %ReportInfo{} =
               report_info = TenantRepo.get_by(ReportInfo, id: created_report.report_info_id)

      assert report_info.org_id == org.org_id

      # ReportJob

      assert [%{args: job_args, scheduled_at: job_scheduled_at}] =
               all_enqueued(worker: Carrier.Works.ReportJob)

      assert job_args == %{
               "org_id" => org.org_id,
               "report_id" => created_report.id,
               "report_info_id" => created_report.report_info_id,
               "datetime" =>
                 job_scheduled_at |> DateTime.truncate(:second) |> DateTime.to_iso8601()
             }

      assert job_scheduled_at |> DateTime.to_time() |> Time.compare(~T[10:00:00]) == :eq

      # ReportLog

      report_log = TenantRepo.get_by(ReportLog, report_id: created_report.id)

      assert report_log.org_id == created_report.org_id
      assert report_log.report_id == created_report.id
    end

    test "with hourly report", %{
      org: org,
      user: user,
      data_target: data_target,
      data_source: data_source
    } do
      params = %{
        org_id: org.org_id,
        user_id: user.id,
        name: "Hourly Report",
        interval: :hourly,
        trigger_time: nil,
        timezone: "Asia/Seoul",
        data_target_info: %{
          data_target_id: data_target.id,
          target: :slack,
          params: %{
            channel_id: "channel_id",
            channel_name: "channel_name",
            channel_type: "public_channel"
          }
        },
        data_source_info: %{
          data_source_id: data_source.id,
          source: :postgres,
          sql_template: "sql",
          timezone: "Asia/Seoul",
          period: 28,
          window_size: 7,
          comparing_period: 7,
          columns: ["total_revenue"]
        }
      }

      assert {:ok, created_report} = Reports.create_report(params)

      # ReportJob

      TenantRepo.set_skip_org_id()

      assert [%{scheduled_at: job_scheduled_at}] = all_enqueued(worker: Carrier.Works.ReportJob)

      assert same_values?(
               job_scheduled_at,
               created_report.created_at |> DateTimeHelper.calc_next_hourly()
             )
    end
  end

  describe "list_reports/0" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report_info0 = TenantFactory.insert(:report_info, org_id: org.org_id)
      report_info1 = TenantFactory.insert(:report_info, org_id: org.org_id)

      deleted_report_info =
        TenantFactory.insert(:report_info, org_id: org.org_id, deleted_at: DateTime.utc_now())

      now = DateTime.utc_now()

      report0 =
        TenantFactory.insert(:report,
          org_id: org.org_id,
          report_info: report_info0,
          created_at: now |> Timex.shift(days: -1)
        )

      report1 =
        TenantFactory.insert(:report,
          org_id: org.org_id,
          report_info: report_info1,
          created_at: now
        )

      _old_report =
        TenantFactory.insert(:report,
          org_id: org.org_id,
          report_info: report_info0,
          created_at: now |> Timex.shift(days: -2)
        )

      _deleted_report =
        TenantFactory.insert(:report, org_id: org.org_id, report_info: deleted_report_info)

      _report_of_another_org = TenantFactory.insert(:report)

      TenantFactory.insert(:report_log,
        report: report0,
        status: :succeeded,
        scheduled_at: now |> Timex.shift(days: -2)
      )

      last_report_log0 =
        TenantFactory.insert(:report_log,
          report: report0,
          status: :failed,
          scheduled_at: now |> Timex.shift(days: -1)
        )

      last_report_log1 =
        TenantFactory.insert(:report_log,
          report: report1,
          status: :failed
        )

      %{reports: [report0, report1], last_report_logs: [last_report_log0, last_report_log1]}
    end

    test "with valid params", %{
      reports: [report0, report1],
      last_report_logs: [last_report_log0, last_report_log1]
    } do
      assert {:ok, [fetched_report0, fetched_report1]} = Reports.list_reports()
      assert same_records?(fetched_report0, report1)
      assert same_records?(fetched_report1, report0)

      assert same_records?(fetched_report0.last_report_log, last_report_log1)
      assert same_records?(fetched_report1.last_report_log, last_report_log0)

      assert %DataTargetInfo{params: data_target_info_params} = report0.data_target_info
      assert %{} = data_target_info_params
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
      assert %DataTargetInfo{params: data_target_info_params} = report.data_target_info
      assert %{} = data_target_info_params
    end

    test "with invalid report_id" do
      assert {:error, {:resource_not_found, %{target: Report}}} = Reports.fetch_report(0)
    end

    test "with deleted report_id", %{org: org} do
      deleted_report_info =
        TenantFactory.insert(:report_info, org_id: org.org_id, deleted_at: DateTime.utc_now())

      report = TenantFactory.insert(:report, org_id: org.org_id, report_info: deleted_report_info)

      assert {:error, {:resource_not_found, %{target: Report}}} = Reports.fetch_report(report.id)

      deleted_report =
        TenantFactory.insert(:report, org_id: org.org_id, deleted_at: DateTime.utc_now())

      assert {:error, {:resource_not_found, %{target: Report}}} =
               Reports.fetch_report(deleted_report.id)
    end
  end

  describe "update_report/2" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report = TenantFactory.insert(:report, org_id: org.org_id)

      %{report: report}
    end

    test "with valid params", %{report: report} do
      params = %{
        org_id: report.org_id,
        user_id: report.user_id,
        name: "Updated Daily Report",
        interval: :daily,
        trigger_time: ~T[10:00:00],
        timezone: "Asia/Seoul",
        data_target_info: %{
          data_target_id: report.data_target_info.data_target_id,
          target: :slack,
          params: %{
            channel_id: "channel_id",
            channel_name: "channel_name",
            channel_type: "public_channel"
          }
        },
        data_source_info: %{
          data_source_id: report.data_source_info.data_source_id,
          source: :postgres,
          sql_template: "sql",
          timezone: "Asia/Seoul",
          period: 28,
          window_size: 7,
          comparing_period: 7,
          columns: ["total_revenue"]
        }
      }

      assert {:ok, updated_report} = Reports.update_report(report.id, params)
      assert updated_report.report_info_id == report.report_info_id
      assert updated_report.name == "Updated Daily Report"

      deleted_report = reload!(report, TenantRepo)

      assert deleted_report.deleted_at != nil
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

      # ReportInfo

      TenantRepo.set_skip_org_id()

      assert %ReportInfo{} =
               report_info = TenantRepo.get_by(ReportInfo, id: report.report_info_id)

      assert report_info.deleted_at != nil
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
        report_info_id: report.report_info_id,
        report_id: report.id,
        report_job_id: 1,
        scheduled_at: DateTime.utc_now() |> Timex.shift(days: 1)
      }

      assert {:ok, scheduled_report_log} = Reports.record_scheduled_report_log(params)

      assert same_fields?(scheduled_report_log, params, [
               :org_id,
               :report_info_id,
               :report_id,
               :report_job_id,
               :scheduled_at
             ])

      assert scheduled_report_log.status == :scheduled
      assert scheduled_report_log.created_at != nil
    end
  end

  describe "record_tried_report_log/1" do
    setup do
      report = TenantFactory.insert(:report)
      _report_log = TenantFactory.insert(:report_log, report: report, status: :scheduled)

      TenantRepo.put_org_id(report.org_id)

      %{report: report}
    end

    test "with valid attrs", %{report: report} do
      params = %{
        report_id: report.id
      }

      assert {:ok, tried_report_log} = Reports.record_tried_report_log(params)
      assert tried_report_log.status == :tried
      assert tried_report_log.tried_at != nil
    end
  end

  describe "record_succeeded_report_log/1" do
    setup do
      report = TenantFactory.insert(:report)
      _report_log = TenantFactory.insert(:report_log, report: report, status: :tried)

      TenantRepo.put_org_id(report.org_id)

      %{report: report}
    end

    test "with valid attrs", %{report: report} do
      params = %{
        report_id: report.id
      }

      assert {:ok, succeeded_report_log} = Reports.record_succeeded_report_log(params)
      assert succeeded_report_log.status == :succeeded
      assert succeeded_report_log.succeeded_at != nil
    end
  end

  describe "record_failed_report_log/1" do
    setup do
      report = TenantFactory.insert(:report)
      _report_log = TenantFactory.insert(:report_log, report: report, status: :tried)

      TenantRepo.put_org_id(report.org_id)

      %{report: report}
    end

    test "with valid attrs", %{report: report} do
      error_message = "error~"

      assert {:ok, failed_report_log} =
               Reports.record_failed_report_log(%{
                 report_id: report.id,
                 error_message: error_message
               })

      assert failed_report_log.status == :failed
      assert failed_report_log.error_message == error_message
      assert failed_report_log.failed_at != nil
    end
  end

  describe "record_cancelled_report_log/1" do
    setup do
      report = TenantFactory.insert(:report)
      _report_log = TenantFactory.insert(:report_log, report: report, status: :tried)

      TenantRepo.put_org_id(report.org_id)

      %{report: report}
    end

    test "with valid attrs", %{report: report} do
      assert {:ok, cancelled_report_log} =
               Reports.record_cancelled_report_log(%{report_id: report.id})

      assert cancelled_report_log.status == :cancelled
      assert cancelled_report_log.cancelled_at != nil
    end
  end

  describe "update_report_log/1" do
    setup do
      report_log = TenantFactory.insert(:report_log, status: :tried)

      %{report_log: report_log}
    end

    test "with payload", %{report_log: report_log} do
      payload = [%{"key" => "value"}]

      assert {:ok, updated_report_log} =
               Reports.update_report_log(report_log, %{payload: payload})

      assert updated_report_log.payload == payload
    end
  end

  describe "list_report_logs/0" do
    setup do
      now = DateTime.utc_now()

      org = TenantFactory.insert(:org)

      report0 = TenantFactory.insert(:report, org_id: org.org_id)
      report1 = TenantFactory.insert(:report, org_id: org.org_id)

      report_log0 =
        TenantFactory.insert(:report_log,
          report: report0,
          status: :succeeded,
          scheduled_at: now |> Timex.shift(days: -2)
        )

      report_log1 =
        TenantFactory.insert(:report_log,
          report: report1,
          status: :scheduled,
          scheduled_at: now |> Timex.shift(days: -1)
        )

      report_log2 =
        TenantFactory.insert(:report_log,
          report: report0,
          status: :scheduled,
          scheduled_at: now |> Timex.shift(days: -1)
        )

      TenantRepo.put_org_id(org.org_id)

      %{report_logs: [report_log0, report_log1, report_log2]}
    end

    test "test", %{report_logs: [report_log0, report_log1, report_log2]} do
      assert {:ok, [fetched_report_log0, fetched_report_log1, fetched_report_log2]} =
               Reports.list_report_logs()

      assert same_records?(fetched_report_log0, report_log2)
      assert same_records?(fetched_report_log1, report_log1)
      assert same_records?(fetched_report_log2, report_log0)

      assert same_records?(fetched_report_log0.report, report_log2.report)
    end
  end

  describe "list_report_logs_by_report_id/1" do
    setup do
      now = DateTime.utc_now()

      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      report0 = TenantFactory.insert(:report, org_id: org.org_id)
      report1 = TenantFactory.insert(:report, org_id: org.org_id)

      report_log0 =
        TenantFactory.insert(:report_log,
          report: report0,
          status: :succeeded,
          scheduled_at: now |> Timex.shift(days: -2)
        )

      _report_log_of_another_report =
        TenantFactory.insert(:report_log,
          report: report1,
          status: :scheduled,
          scheduled_at: now |> Timex.shift(days: -1)
        )

      report_log1 =
        TenantFactory.insert(:report_log,
          report: report0,
          status: :scheduled,
          scheduled_at: now |> Timex.shift(days: -1)
        )

      %{report: report0, report_logs: [report_log0, report_log1]}
    end

    test "test", %{report: report, report_logs: [report_log0, report_log1]} do
      assert {:ok, [fetched_report_log0, fetched_report_log1]} =
               Reports.list_report_logs_by_report_id(report.id)

      assert same_records?(fetched_report_log0, report_log1)
      assert same_records?(fetched_report_log1, report_log0)

      assert same_records?(fetched_report_log0.report, report_log1.report)
    end
  end
end
