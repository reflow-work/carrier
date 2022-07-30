defmodule CarrierWeb.DataSourceLive do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Icon

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:step, "step-1")
      |> assign(:source, nil)
      |> assign(:name, nil)
      |> assign(:host, nil)
      |> assign(:port, nil)
      |> assign(:database, nil)
      |> assign(:username, nil)
      |> assign(:password, nil)

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

    socket =
      socket
      |> assign(:name, name)
      |> assign(:host, host)
      |> assign(:port, port)
      |> assign(:database, database)
      |> assign(:username, username)
      |> assign(:password, password)

    {:noreply, socket}
  end

  @impl true
  def handle_event("connect_data_source", %{"data_source" => _data_source}, socket) do
    "TODO: connect!" |> IO.inspect()
    {:noreply, socket}
  end
end
