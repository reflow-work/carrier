defmodule Carrier.Works.SubscriptionActivatingJob do
  use Oban.Worker,
    queue: :subscription_activating,
    priority: 0,
    max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # activate subscription

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(1)
end
