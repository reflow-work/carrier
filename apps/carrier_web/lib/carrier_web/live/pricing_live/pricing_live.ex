defmodule CarrierWeb.PricingLive do
  use CarrierWeb, :live_view
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
end
