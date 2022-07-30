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
  def handle_event("change_data_source", %{"data_source" => data_source}, socket) do
    %{
      "name" => name,
      "host" => host,
      "port" => port,
      "database" => database,
      "username" => username,
      "password" => password
    } = data_source

    {:noreply, socket}
  end

  @impl true
  def handle_event("connect_data_source", %{"data_source" => _data_source}, socket) do
    "TODO: connect!" |> IO.inspect()
    {:noreply, socket}
  end
end
