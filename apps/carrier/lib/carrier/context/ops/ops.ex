defmodule Carrier.Ops do
  use Carrier.{Accounts, Secrets, Reports, Billing, Payments}
  import Ecto.Query, only: [from: 2]
  alias Carrier.{Repo, TenantRepo}

  def restart_failed_report(report_log_id) do
    Repo.wrap_transaction(fn ->
      with {:ok, %ReportLog{report_job_id: report_job_id} = report_log} <-
             retry_failed_report_log(report_log_id),
           {:ok, %ReportJob{} = report_job} <- retry_discarded_report_job(report_job_id) do
        {:ok, {report_log, report_job}}
      end
    end)
  end

  def delete_org(org_id, org_name) do
    TenantRepo.put_org_id(org_id)

    now = DateTime.utc_now()

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Org{name: ^org_name} = org} <- Accounts.fetch_org() do
        [
          Subscription,
          Payment,
          CreditCard,
          Report,
          ReportInfo,
          DataSource,
          Integration,
          ConnInfo,
          User,
          Org
        ]
        |> Enum.each(&delete_not_deleted(&1, now))

        {:ok, org}
      else
        _ -> {:error, :invalid_org}
      end
    end)
  end

  defp delete_not_deleted(module, now) do
    from(x in module, where: is_nil(x.deleted_at), update: [set: [deleted_at: ^now]])
    |> TenantRepo.update_all([])
  end

  def hard_delete_org(org_id, org_name) do
    TenantRepo.put_org_id(org_id)

    with {:ok, org} <-
           TenantRepo.wrap_transaction(fn ->
             with {:ok, %Org{name: ^org_name} = org} <- Accounts.fetch_org() do
               TenantRepo.delete_all(Subscription)
               TenantRepo.delete_all(Payment)
               TenantRepo.delete_all(CreditCard)
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
