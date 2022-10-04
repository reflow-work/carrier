defmodule Carrier.Reports do
  require Logger
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
           {:ok, _job} <- create_job_from_report(report, report.created_at) do
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
        report_id: report_id,
        scheduled_at: scheduled_at
      }) do
    ReportLog.record_scheduled(%{
      org_id: org_id,
      report_id: report_id,
      created_at: DateTime.utc_now(),
      scheduled_at: scheduled_at
    })
    |> TenantRepo.insert()
  end

  def record_tried_report_log(%{
        report_id: report_id
      }) do
    TenantRepo.wrap_transaction(fn ->
      ReportLog.record_tried(%{report_id: report_id, tried_at: DateTime.utc_now()})
      |> TenantRepo.update_all([])
      |> case do
        {1, [%ReportLog{} = report_log]} -> {:ok, report_log}
        _ -> {:error, :failed_to_record_tried_report_log}
      end
    end)
  end

  def record_succeeded_report_log(%{report_id: report_id}) do
    TenantRepo.wrap_transaction(fn ->
      ReportLog.record_succeeded(%{report_id: report_id, succeeded_at: DateTime.utc_now()})
      |> TenantRepo.update_all([])
      |> case do
        {1, [%ReportLog{} = report_log]} -> {:ok, report_log}
        _ -> {:error, :failed_to_record_succeeded_report_log}
      end
    end)
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

  def create_job_from_report(%Report{} = report, %DateTime{} = base_datetime) do
    scheduled_at = DateTimeHelper.get_next_with_time(base_datetime, report.trigger_time)

    TenantRepo.wrap_transaction(fn ->
      with {:ok, report_job} <-
             %{org_id: report.org_id, report_id: report.id, datetime: scheduled_at}
             |> ReportJob.new(
               scheduled_at: scheduled_at,
               meta: %{org_id: report.org_id}
             )
             |> TenantRepo.insert(),
           {:ok, %ReportLog{}} <-
             record_scheduled_report_log(%{
               org_id: report.org_id,
               report_id: report.id,
               scheduled_at: scheduled_at
             }) do
        {:ok, report_job}
      end
    end)
    |> tap(fn _ ->
      Logger.debug("next job of report_id: #{report.id} is scheduled_at #{inspect(scheduled_at)}")
    end)
  end
end
