defmodule Carrier.Reports do
  alias Carrier.Reports.Report
  alias Carrier.TenantRepo

  def create_report(%{
        org_id: org_id,
        name: name,
        trigger_time: trigger_time,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    Report.create(%{
      org_id: org_id,
      name: name,
      trigger_time: trigger_time,
      integration_info: integration_info,
      data_source_info: data_source_info
    })
    |> TenantRepo.insert()
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
end
