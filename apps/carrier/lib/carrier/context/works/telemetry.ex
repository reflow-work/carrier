defmodule Carrier.Context.Works.Telemetry do
  use Carrier.Reports
  alias Carrier.Core.Async
  alias Carrier.Tenant

  def handle_event(
        [:oban, :job, :exception],
        _measurements,
        %{
          worker: "Carrier.Works.ReportJob",
          state: :discard,
          id: job_id,
          args: %{"org_id" => org_id}
        } = _metadata,
        _config
      ) do
    Tenant.put_org_id(org_id)
    Async.run(fn -> Reports.notify_report_job_discarded(job_id) end)
  end

  def handle_event([:oban, :job, :exception], _measurements, _metadata, _config) do
    nil
  end
end
