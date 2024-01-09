defmodule Carrier.Reports.Super do
  use Carrier.Core.Cache
  alias Carrier.Reports.ReportLog
  alias Carrier.Repo

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_report_log_count, []},
              opts: [ttl: Cache.ttl(:timer.minutes(1))]
            )
  def get_report_log_count() do
    ReportLog
    |> Repo.aggregate(:count, :id, org_id: :skip)
    |> then(&{:ok, &1})
  end

  def list_error_report_logs() do
    ReportLog.list_error()
    |> Repo.all(org_id: :skip)
    |> then(&{:ok, &1})
  end
end
