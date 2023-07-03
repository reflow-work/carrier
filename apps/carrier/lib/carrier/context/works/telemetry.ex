defmodule Carrier.Context.Works.Telemetry do
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
    # TODO: remove it
    IO.inspect(binding())
  end

  def handle_event([:oban, :job, :exception], _measurements, _metadata, _config) do
    nil
  end
end
