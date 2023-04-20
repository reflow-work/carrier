defmodule Carrier.Works.SubscriptionExpiringJob do
  use Oban.Worker,
    queue: :subscription_expiring,
    priority: 0,
    max_attempts: 2

  use Carrier.Billing
  require Logger
  alias Carrier.TenantRepo

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"org_id" => org_id, "subscription_id" => subscription_id}
      }) do
    TenantRepo.put_org_id(org_id)

    with {:ok, %Subscription{}} <- Billing.expire_subscription(subscription_id) do
      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Failed to expire subscription: subscription_id: #{subscription_id}, #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(1)
end
