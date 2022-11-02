defmodule Carrier.Ops do
  alias Carrier.Reports.{ReportLog, ReportJob}
  alias Carrier.Repo

  def restart_failed_report(report_log_id) do
    Repo.wrap_transaction(fn ->
      with {:ok, %ReportLog{report_job_id: report_job_id}} <-
             retry_failed_report_log(report_log_id),
           {:ok, %ReportJob{}} <- retry_discarded_report_job(report_job_id) do
        {:ok, nil}
      end
    end)
  end

  defp retry_failed_report_log(report_log_id) do
    Repo.wrap_transaction(fn ->
      ReportLog.retry_failed(%{report_log_id: report_log_id})
      |> Repo.update_all([])
      |> case do
        {1, [%ReportLog{} = report_log]} -> {:ok, report_log}
        _ -> {:error, :failed_to_retry_failed_report_log}
      end
    end)
  end

  defp retry_discarded_report_job(report_job_id) do
    Repo.wrap_transaction(fn ->
      ReportJob.retry_discarded(%{report_job_id: report_job_id})
      |> Repo.update_all([])
      |> case do
        {1, [%ReportJob{} = report_job]} -> {:ok, report_job}
        _ -> {:error, :failed_to_retry_failed_report_jog}
      end
    end)
  end
end
