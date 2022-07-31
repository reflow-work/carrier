defmodule CarrierWeb.DataSourceLive do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Icon

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:step, "step-1")
      |> assign(:type, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_step", %{"step" => step}, socket) do
    socket = socket |> assign(:step, step)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_source", %{"source" => source}, socket) do
    socket =
      socket
      |> assign(:step, "step-2")
      |> assign(:source, source)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_conn_info", %{"conn_info" => conn_info}, socket) do
    %{
      "name" => name,
      "host" => host,
      "port" => port,
      "username" => username,
      "password" => password,
      "database" => database
    } = conn_info

    conn_info |> IO.inspect()

    {:noreply, socket}
  end
end
