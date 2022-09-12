defmodule Carrier.Reports do
  alias Carrier.Reports.Report
  alias Carrier.Works.QueryJob
  alias Carrier.TenantRepo

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
           {:ok, _job} <- create_job_from_report(report) do
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
      %Report{} = report -> {:ok, report}
      nil -> {:error, {:resource_not_found, target: Report, conditions: %{report_id: report_id}}}
    end
  end

  def delete_report(report_id) do
    with {:ok, %Report{} = report} <- fetch_report(report_id),
         {:ok, deleted_report} <-
           report |> Report.delete(DateTime.utc_now()) |> TenantRepo.delete() do
      {:ok, deleted_report}
    end
  end

  defp create_job_from_report(%Report{} = report) do
    # TODO: calc next report datetime
    scheduled_at = DateTime.utc_now()

    report
    |> Map.take([:org_id, :name, :trigger_time, :integration_info, :data_source_info])
    |> Map.merge(%{
      report_id: report.id,
      datetime: scheduled_at
    })
    |> Map.delete(:id)
    |> Map.put(:scheduled_at, scheduled_at)
    |> QueryJob.new(meta: %{org_id: report.org_id})
    |> then(&Oban.insert(CarrierWorker.Oban, &1))
  end
end
