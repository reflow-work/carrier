defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view
  alias Carrier.Billing

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

  defp format_datetime(datetime, timezone) when not is_nil(datetime) and not is_nil(timezone) do
    datetime
    |> DateTime.shift_zone!(timezone)
    |> Timex.format!("{YYYY}년 {M}월 {D}일")
  end
end
