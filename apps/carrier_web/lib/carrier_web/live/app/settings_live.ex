defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_subscription, nil)
      |> assign(:pending_subscription, nil)
      |> load_active_subscription()
      |> load_pending_subscription()

    {:ok, socket}
  end

  @impl true
  def handle_event("smartlook_anonymize", _params, socket) do
    socket =
      socket
      |> push_event("smartlook_anonymize", %{})

    {:noreply, socket}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp load_active_subscription(socket) do
    case Billing.fetch_active_subscription() do
      {:ok, subscription} ->
        socket |> assign(:active_subscription, subscription)

      {:error, _} ->
        socket
    end
  end

  defp load_pending_subscription(socket) do
    case Billing.fetch_pending_subscription() do
      {:ok, subscription} ->
        socket |> assign(:pending_subscription, subscription)

      {:error, _} ->
        socket
    end
  end
end
