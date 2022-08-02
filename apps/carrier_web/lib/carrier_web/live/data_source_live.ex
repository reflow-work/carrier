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
      |> assign(:conn_info, %{
        name: nil,
        source: nil,
        hostname: nil,
        port: nil,
        username: nil,
        password: nil,
        database: nil
      })

    {:ok, socket}
  end

  @impl true
  def handle_event("change_step", %{"step" => step}, socket) do
    socket = socket |> assign(:step, step)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_source", %{"source" => source_str}, socket) do
    source = String.to_existing_atom(source_str)

    socket =
      socket
      |> assign(:step, "step-2")
      |> update(:conn_info, fn conn_info -> conn_info |> Map.put(:source, source) end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_conn_info", %{"conn_info" => conn_info_input}, socket) do
    %{
      "name" => name,
      "hostname" => hostname,
      "port" => port,
      "username" => username,
      "password" => password,
      "database" => database
    } = conn_info_input

    conn_info_params = %{
      name: name,
      source: socket.assigns.conn_info.source,
      hostname: hostname,
      port: port,
      username: username,
      password: password,
      database: database
    }

    socket = socket |> assign(:conn_info, conn_info_params)

    # test connection

    # create conn_info
    socket = socket |> create_conn_info(conn_info_params)

    {:noreply, socket}
  end

  defp create_conn_info(socket, params) do
    params = params |> Map.put(:org_id, socket.assigns.org_id)

    case do_create_conn_info(params) do
      {:ok, %ConnInfo{}} ->
        socket
        |> push_redirect(to: Routes.report_new_path(socket, :new))

      error ->
        socket
        |> put_flash(:error, inspect(error))
    end
  end

  defp do_create_conn_info(%{
         org_id: org_id,
         name: name,
         source: source,
         hostname: hostname,
         port: port,
         username: username,
         password: password,
         database: database
       }) do
    Secrets.create_conn_info(%{
      org_id: org_id,
      name: name,
      source: source,
      info: %{
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database
      }
    })
  end
end
