defmodule Carrier.Reports do
  require Logger
  alias Carrier.Reports.{ReportInfo, Report, ReportLog, ReportJob}
  alias Carrier.Works
  alias Carrier.TenantRepo
  alias Carrier.Core.DateTimeHelper

  defmacro __using__([]) do
    quote do
      alias Carrier.Reports

      alias Carrier.Reports.{
        ReportInfo,
        Report,
        ReportLog,
        ReportJob,
        DataSourceInfo,
        DataTargetInfo,
        ImageGenerator
      }
    end
  end

  def fetch_report_info(report_info_id) do
    ReportInfo.fetch(report_info_id)
    |> TenantRepo.one()
    |> case do
      %ReportInfo{} = report_info ->
        {:ok, report_info}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: ReportInfo, conditions: %{report_info_id: report_info_id}}}}
    end
  end

  def create_report(%{
        org_id: org_id,
        user_id: user_id,
        name: name,
        trigger_time: trigger_time,
        timezone: timezone,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %ReportInfo{} = report_info} <-
             ReportInfo.create(%{org_id: org_id}) |> TenantRepo.insert(),
           {:ok, %Report{} = report} <-
             Report.create(%{
               org_id: org_id,
               report_info_id: report_info.id,
               user_id: user_id,
               name: name,
               trigger_time: trigger_time,
               timezone: timezone,
               integration_info: integration_info,
               data_source_info: data_source_info
             })
             |> TenantRepo.insert(),
           {:ok, _job} <- create_job_from_report(report, report.created_at) do
        {:ok, report |> Report.load_data_source_info()}
      end
    end)
  end

  def list_reports() do
    Report.list()
    |> TenantRepo.all()
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> then(&{:ok, &1 |> Enum.map(fn report -> report |> Report.load_data_source_info() end)})
  end

  def fetch_report(report_id) do
    Report.fetch(report_id)
    |> TenantRepo.one()
    |> case do
      %Report{} = report ->
        {:ok, report |> Report.load_data_source_info()}

      nil ->
        {:error, {:resource_not_found, %{target: Report, conditions: %{report_id: report_id}}}}
    end
  end

  def update_report(report_id, %{
        org_id: org_id,
        user_id: user_id,
        name: name,
        trigger_time: trigger_time,
        timezone: timezone,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Report{} = report} <- fetch_report(report_id),
           {:ok, %Report{} = created_report} <-
             Report.create(%{
               org_id: org_id,
               report_info_id: report.report_info_id,
               user_id: user_id,
               name: name,
               trigger_time: trigger_time,
               timezone: timezone,
               integration_info: integration_info,
               data_source_info: data_source_info
             })
             |> TenantRepo.insert(),
           {:ok, _deleted_report} <-
             report |> Report.delete(DateTime.utc_now()) |> TenantRepo.update(),
           {:ok, _job} <- create_job_from_report(created_report, created_report.created_at) do
        {:ok, created_report |> Report.load_data_source_info()}
      end
    end)
  end

  def delete_report(report_id) do
    with {:ok, %Report{} = report} <- fetch_report(report_id),
         {:ok, %ReportInfo{} = report_info} <- fetch_report_info(report.report_info_id),
         deleted_at = DateTime.utc_now(),
         {:ok, deleted_report} <-
           report |> Report.delete(deleted_at) |> TenantRepo.update(),
         {:ok, _deleted_report_info} <-
           report_info |> ReportInfo.delete(deleted_at) |> TenantRepo.update() do
      {:ok, deleted_report}
    end
  end

  def record_scheduled_report_log(
        %{
          org_id: org_id,
          report_info_id: report_info_id,
          report_id: report_id,
          report_job_id: report_job_id,
          scheduled_at: scheduled_at
        },
        reader \\ %{repo: TenantRepo}
      ) do
    ReportLog.record_scheduled(%{
      org_id: org_id,
      report_info_id: report_info_id,
      report_id: report_id,
      report_job_id: report_job_id,
      created_at: DateTime.utc_now(),
      scheduled_at: scheduled_at
    })
    |> reader.repo.insert()
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

  def record_failed_report_log(%{report_id: report_id, error_message: error_message}) do
    TenantRepo.wrap_transaction(fn ->
      ReportLog.record_failed(%{
        report_id: report_id,
        failed_at: DateTime.utc_now(),
        error_message: error_message
      })
      |> TenantRepo.update_all([])
      |> case do
        {1, [%ReportLog{} = report_log]} -> {:ok, report_log}
        _ -> {:error, :failed_to_record_failed_report_log}
      end
    end)
  end

  def record_cancelled_report_log(%{report_id: report_id}) do
    TenantRepo.wrap_transaction(fn ->
      ReportLog.record_cancelled(%{
        report_id: report_id,
        cancelled_at: DateTime.utc_now()
      })
      |> TenantRepo.update_all([])
      |> case do
        {1, [%ReportLog{} = report_log]} -> {:ok, report_log}
        _ -> {:error, :failed_to_record_cancelled_report_log}
      end
    end)
  end

  def update_report_log(%ReportLog{} = report_log, params) do
    ReportLog.update(report_log, params)
    |> TenantRepo.update()
  end

  def create_job_from_report(
        %Report{} = report,
        %DateTime{} = base_datetime,
        reader \\ %{repo: TenantRepo}
      ) do
    scheduled_at = DateTimeHelper.get_next_with_time(base_datetime, report.trigger_time)

    reader.repo.wrap_transaction(fn ->
      with {:ok, report_job} <-
             %{
               org_id: report.org_id,
               report_id: report.id,
               report_info_id: report.report_info_id,
               datetime: scheduled_at
             }
             |> Works.ReportJob.new(
               scheduled_at: scheduled_at,
               meta: %{org_id: report.org_id}
             )
             |> reader.repo.insert(),
           {:ok, %ReportLog{}} <-
             record_scheduled_report_log(
               %{
                 org_id: report.org_id,
                 report_info_id: report.report_info_id,
                 report_id: report.id,
                 report_job_id: report_job.id,
                 scheduled_at: scheduled_at
               },
               reader
             ) do
        {:ok, report_job}
      end
    end)
    |> tap(fn _ ->
      Logger.debug(
        "next report job of report_id: #{report.id} is scheduled_at #{inspect(scheduled_at)}"
      )
    end)
  end

  def list_report_logs() do
    ReportLog.list()
    |> ReportLog.preload_report()
    |> TenantRepo.all()
    |> then(&{:ok, &1})
  end
end
