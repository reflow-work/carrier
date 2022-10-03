defmodule Carrier.Reports do
  alias Carrier.Reports.{Report, ReportLog}
  alias Carrier.Works.ReportJob
  alias Carrier.TenantRepo
  alias Carrier.Core.DateTimeHelper

  def create_report(%{
        org_id: org_id,
        name: name,
        trigger_time: trigger_time,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Report{} = report} <-
             Report.create(%{
               org_id: org_id,
               name: name,
               trigger_time: trigger_time,
               integration_info: integration_info,
               data_source_info: data_source_info
             })
             |> TenantRepo.insert(),
           {:ok, _job} <- create_job_from_report(report),
           {:ok, %ReportLog{}} <-
             record_scheduled_report_log(%{
               org_id: org_id,
               report_id: report.id
             }) do
        {:ok, report}
      end
    end)
  end

  def list_reports() do
    Report.list()
    |> TenantRepo.all()
    |> then(&{:ok, &1})
  end

  def fetch_report(report_id) do
    Report.fetch(report_id)
    |> TenantRepo.one()
    |> case do
      %Report{} = report ->
        {:ok, report}

      nil ->
        {:error, {:resource_not_found, %{target: Report, conditions: %{report_id: report_id}}}}
    end
  end

  def delete_report(report_id) do
    with {:ok, %Report{} = report} <- fetch_report(report_id),
         {:ok, deleted_report} <-
           report |> Report.delete(DateTime.utc_now()) |> TenantRepo.update() do
      {:ok, deleted_report}
    end
  end

  def record_scheduled_report_log(%{
        org_id: org_id,
        report_id: report_id
      }) do
    ReportLog.record_scheduled(%{
      org_id: org_id,
      report_id: report_id,
      scheduled_at: DateTime.utc_now()
    })
    |> TenantRepo.insert()
  end

  def record_succeeded_report_log(%ReportLog{} = report_log) do
    report_log
    |> ReportLog.record_succeeded(%{
      sent_at: DateTime.utc_now()
    })
    |> TenantRepo.update()
  end

  def record_failed_report_log(
        %ReportLog{} = report_log,
        %{
          error_message: error_message
        }
      ) do
    report_log
    |> ReportLog.record_failed(%{
      error_message: error_message
    })
    |> TenantRepo.update()
  end

  defp create_job_from_report(%Report{} = report) do
    scheduled_at = DateTimeHelper.get_next_with_time(report.created_at, report.trigger_time)

    %{org_id: report.org_id, report_id: report.id, datetime: scheduled_at}
    |> ReportJob.new(
      scheduled_at: scheduled_at,
      meta: %{org_id: report.org_id}
    )
    |> TenantRepo.insert()
  end
end
