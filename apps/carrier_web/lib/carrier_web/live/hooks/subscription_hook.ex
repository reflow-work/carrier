defmodule CarrierWeb.SubscriptionHook do
  use CarrierWeb, :live_hook
  alias Carrier.Billing

  def on_mount(:default, _params, session, socket) do
    case Billing.have_active_subscription?() do
      true ->
        {:cont, socket}

      _ ->
        to = get_redirect_path(session["user_return_to"])
        socket = socket |> push_navigate(to: to)
        {:halt, socket}
    end
  end

  defp get_redirect_path(user_return_to) do
    case user_return_to do
      nil -> "/app/subscriptions/new"
      "" -> "/app/subscriptions/new"
      _ -> user_return_to
    end
  end
end
