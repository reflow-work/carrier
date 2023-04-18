defmodule Carrier.Reports.Super do
  use Carrier.Core.Cache
  alias Carrier.Reports.ReportLog
  alias Carrier.TenantRepo

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_report_log_count, []},
              opts: [ttl: Cache.ttl(:timer.minutes(1))]
            )
  def get_report_log_count() do
    ReportLog
    |> TenantRepo.aggregate(:count, :id, skip_org_id: true)
    |> then(&{:ok, &1})
  end
end
