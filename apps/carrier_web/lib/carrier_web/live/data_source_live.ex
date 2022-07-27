defmodule CarrierWeb.DataSourceLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:source, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_source", %{"source" => source}, socket) do
    source |> IO.inspect()

    socket =
      socket
      |> assign(:source, source)

    {:noreply, socket}
  end
end
