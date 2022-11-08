defmodule CarrierWeb.SettingsLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    case connected?(socket) do
      true ->
        socket = socket |> push_event("amplitude_log_event", %{eventName: "view_settings"})

      false ->
        socket
    end

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
end
