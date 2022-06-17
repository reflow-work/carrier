defmodule CarrierWorker.SampleJob do
  use Oban.Worker,
    queue: :sample

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"scheduled_at" => scheduled_at_str} = args, meta: meta}) do
    {:ok, scheduled_at, _} = scheduled_at_str |> DateTime.from_iso8601()

    new_scheduled_at = scheduled_at |> DateTime.add(10, :second)

    Logger.debug("next job is scheduled_at #{inspect(new_scheduled_at)}")

    %{args | "scheduled_at" => new_scheduled_at}
    |> new(meta: meta, scheduled_at: new_scheduled_at)
    |> then(&Oban.insert(CarrierWorker.Oban, &1))

    :ok
  end
end
