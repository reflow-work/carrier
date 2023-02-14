defmodule Carrier.Reports.Super do
  use Carrier.Core.Cache
  alias Carrier.Reports.ReportLog
  alias Carrier.Repo

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_report_log_count, []},
              opts: [ttl: :timer.minutes(1)]
            )
  def get_report_log_count() do
    ReportLog
    |> Repo.aggregate(:count, :id)
    |> then(&{:ok, &1})
  end
end
