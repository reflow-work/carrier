defmodule CarrierWeb.SubscriptionRedirectionHook do
  use CarrierWeb, :live_hook
  alias Carrier.Billing

  def on_mount(:default, _params, _session, socket) do
    case Billing.have_active_non_trial_subscription?() do
      true ->
        socket = socket |> push_navigate(to: ~p"/app/settings")
        {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end
end
