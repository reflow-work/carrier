defmodule Carrier.Reports do
  alias Carrier.Reports.Report
  alias Carrier.TenantRepo

  def list_reports() do
    Report.list()
    |> TenantRepo.all()
    |> then(&{:ok, &1})
  end
end
