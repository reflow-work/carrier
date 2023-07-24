defmodule CarrierWeb.SubscriptionHook do
  use CarrierWeb, :live_hook
  alias Carrier.Billing

  def on_mount(:default, _params, _session, socket) do
    socket =
      case Billing.fetch_active_subscription() do
        {:ok, subscription} ->
          socket |> assign(:active_subscription, subscription)

        _ ->
          socket |> assign(:active_subscription, nil)
      end

    {:cont, socket}
  end
end
