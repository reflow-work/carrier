defmodule Carrier.Context.Works.Telemetry do
  use Carrier.Reports
  alias Carrier.Core.Async
  alias Carrier.Tenant

  def handle_event(
        [:oban, :job, :exception] = event,
        measurements,
        %{
          job: job,
          reason: reason,
          stacktrace: stacktrace
        } = metadata,
        config
      ) do
    extra =
      job
      |> Map.take([:id, :args, :meta, :queue, :worker])
      |> Map.merge(measurements)

    Sentry.capture_exception(reason, stacktrace: stacktrace, extra: extra)

    do_handle_event(event, measurements, metadata, config)
  end

  defp do_handle_event(
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

  defp do_handle_event([:oban, :job, :exception], _measurements, _metadata, _config) do
    nil
  end
end
