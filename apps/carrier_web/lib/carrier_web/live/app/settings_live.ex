defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view
  use Carrier.Billing
  alias Carrier.Core.{TimezoneHelper, DateHelper}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> load_active_subscription()

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
        nil
    end
  end

  defp format_next_payment_date(%Subscription{end_on: end_on} = _active_subscription) do
    end_on
    |> TimezoneHelper.apply_timezone()
    |> DateHelper.safe_format_date()
  end
end
