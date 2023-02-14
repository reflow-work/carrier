defmodule Carrier.Reports.Super do
  alias Carrier.Reports.ReportLog
  alias Carrier.Repo

  def get_report_log_count() do
    ReportLog
    |> Repo.aggregate(:count, :id)
    |> then(&{:ok, &1})
  end
end
