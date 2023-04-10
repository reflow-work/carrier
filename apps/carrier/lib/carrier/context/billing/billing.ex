defmodule Carrier.Billing do
  use Carrier.Payments
  require Logger
  alias Carrier.Billing.{Plan, Subscription}
  alias Carrier.Billing.Super

  defmacro __using__([]) do
    quote do
      alias Carrier.Billing
      alias Carrier.Billing.{Plan, Subscription}
    end
  end

  # TODO: implement it
  def start_subscription(%{plan_id: plan_id} = params) do
    with {:ok, %Plan{subscribable: true} = plan} <- Super.fetch_plan(plan_id),
         {:ok, %Subscription{} = subscription} <- create_subscription(params),
         {:ok, %Subscription{} = activated_subscription} <- activate_subscription(subscription.id) do
      {:ok, activated_subscription}
    end
  end

  # TODO: implement it
  # TODO: use the same time for expire and activate
  def activate_subscription(subscription_id) do
    with {:ok, %Subscription{status: :pending} = subscription} <-
           fetch_subscription(subscription_id),
         :ok <- expire_prev_subscription(subscription),
         {:ok, maybe_payment} <- pay_subscription(subscription),
         {:ok, %Subscription{} = activated_subscription} <-
           Subscription.activate(subscription, %{payment_id: maybe_payment[:id]}),
         {:ok, maybe_next_subscription} <- create_next_subscription(subscription) do
      {:ok, activated_subscription}
    end
  end

  # TODO: implement it
  defp fetch_subscription(subscription_id) do
    {:ok, %Subscription{id: subscription_id}}
  end

  # TODO: implement it
  defp create_subscription(_params) do
    {:ok, %Subscription{id: 1}}
  end

  # TODO: implement it
  defp create_next_subscription(%Subscription{}) do
    {:ok, %Subscription{}}
  end

  # TODO: implement it
  # TODO: refund?
  defp expire_prev_subscription(%Subscription{prev_subscription_id: prev_subscription_id})
       when not is_nil(prev_subscription_id) do
    with {:ok, %Subscription{} = prev_subscription} <- fetch_subscription(prev_subscription_id),
         {:ok, %Subscription{}} <- do_expire_subscription(prev_subscription_id) do
      :ok
    end
  end

  defp expire_subscription(%Subscription{prev_subscription_id: nil}) do
    :ok
  end

  # TODO: implement it
  defp do_expire_subscription(%Subscription{status: :active} = subscription) do
    with {:ok, %Subscription{} = expired_subscription} <- Subscription.expire(subscription) do
      {:ok, expired_subscription}
    end
  end

  defp do_expire_subscription(%Subscription{status: :expired} = subscription) do
    Logger.warn("Subscription #{subscription.id} is already expired")

    {:ok, subscription}
  end

  defp pay_subscription(%Subscription{}) do
    {:ok, %Payment{}}
  end
end
