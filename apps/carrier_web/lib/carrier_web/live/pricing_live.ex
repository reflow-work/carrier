defmodule CarrierWeb.PricingLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :is_open_toggle, false)
    {:ok, socket, layout: {CarrierWeb.Layouts, :landing}}
  end

  @impl true
  def handle_event("click_link", %{"name" => name, "to" => to}, socket) do
    socket =
      socket
      |> log_event(name, %{
        page_name: "pricing"
      })

    {:noreply, push_navigate(socket, to: to)}
  end

  def handle_event("click_toggle", _, socket) do
    socket = assign(socket, :is_open_toggle, !socket.assigns.is_open_toggle)
    {:noreply, socket}
  end
end
