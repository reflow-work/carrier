defmodule Carrier.Reports do
  alias Carrier.Reports.Report
  alias Carrier.TenantRepo

  def create_reports(%{org_id: org_id, name: name}) do
    Report.create(%{org_id: org_id, name: name})
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
end
