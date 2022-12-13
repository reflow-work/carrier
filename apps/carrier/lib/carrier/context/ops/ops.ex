defmodule Carrier.Ops do
  use Carrier.{Accounts, Secrets, Reports}
  alias Carrier.{Repo, TenantRepo}

  def restart_failed_report(report_log_id) do
    Repo.wrap_transaction(fn ->
      with {:ok, %ReportLog{report_job_id: report_job_id}} <-
             retry_failed_report_log(report_log_id),
           {:ok, %ReportJob{}} <- retry_discarded_report_job(report_job_id) do
        {:ok, nil}
      end
    end)
  end

  def delete_org(org_id, org_name) do
    TenantRepo.put_org_id(org_id)

    with {:ok, org} <-
           TenantRepo.wrap_transaction(fn ->
             with {:ok, %Org{name: ^org_name} = org} <- Accounts.fetch_org() do
               TenantRepo.delete_all(ReportLog)
               TenantRepo.delete_all(Report)
               TenantRepo.delete_all(ReportInfo)
               TenantRepo.delete_all(DataSource)
               TenantRepo.delete_all(Integration)
               TenantRepo.delete_all(ConnInfo)
               TenantRepo.delete_all(User)
               TenantRepo.delete_all(Org)

               {:ok, org}
             else
               _ -> {:error, :invalid_org}
             end
           end) do
      ReportJob.list_by_org_id(org_id) |> Repo.delete_all()

      {:ok, org}
    end
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
