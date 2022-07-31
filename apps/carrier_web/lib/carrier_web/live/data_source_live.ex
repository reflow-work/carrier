defmodule CarrierWeb.DataSourceLive do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Icon
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo

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

    # test connection

    # create conn_info
    socket =
      socket
      |> create_conn_info(%{
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        database: database
      })

    {:noreply, socket}
  end

  defp create_conn_info(socket, params) do
    case do_create_conn_info(params) do
      {:ok, %ConnInfo{}} ->
        socket
        |> put_flash(:info, "succeeded")

      error ->
        socket
        |> put_flash(:error, inspect(error))
    end
  end

  defp do_create_conn_info(%{
         name: name,
         host: host,
         port: port,
         username: username,
         password: password,
         database: database
       }) do
    Secrets.create_conn_info(%{
      org_id: 1,
      name: name,
      type: "postgres",
      info: %{
        host: host,
        port: port,
        username: username,
        password: password,
        database: database
      }
    })
  end
end
