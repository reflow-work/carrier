defmodule Carrier.Works.ReportJob do
  use Oban.Worker,
    queue: :report,
    priority: 2,
    max_attempts: 3

  use Carrier.{Reports, Data}
  require Logger
  alias Carrier.Tenant

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"org_id" => org_id, "report_id" => report_id, "datetime" => datetime_str}
      }) do
    Tenant.put_org_id(org_id)
    Logger.metadata(org_id: org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %ReportLog{} = report_log} <-
           Reports.record_tried_report_log(%{report_id: report_id}),
         {:ok, %Report{} = report} <- Reports.fetch_report(report_id),
         :ok <- send_report(report, datetime, report_log),
         {:ok, _report_log} <- Reports.record_succeeded_report_log(%{report_id: report_id}),
         {:ok, _next_job} <- Reports.create_job_from_report(report, datetime) do
      :ok
    else
      {:error, {:resource_not_found, %{target: Report}}} ->
        Reports.record_cancelled_report_log(%{report_id: report_id})

        {:cancel, :report_is_deleted}

      error ->
        # treated in Works.Telemetry
        error
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)

  defp send_report(
         %Report{data_target_info: data_target_info} = report,
         datetime,
         report_log
       ) do
    with {:ok, threads} <- Data.prepare_threads(report |> Map.put(:datetime, datetime)),
         {:ok, %ReportLog{} = _updated_report_log} <-
           Reports.update_report_log(report_log, %{payload: threads}),
         :ok <- Data.send_messages(report, threads, data_target_info) do
      :ok
    end
  end
end
