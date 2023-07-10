defmodule CarrierWorker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok =
      :telemetry.attach(
        "oban_job_failure",
        [:oban, :job, :exception],
        &Carrier.Context.Works.Telemetry.handle_event/4,
        nil
      )

    children = [
      {Oban, Application.fetch_env!(:carrier_worker, Oban)}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: CarrierWorker.Supervisor)
  end
end
