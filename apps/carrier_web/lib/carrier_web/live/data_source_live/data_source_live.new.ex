defmodule CarrierWeb.DataSourceLive.New do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Icon
  alias CarrierWeb.DataSourceLive.ConnInfoParams
  alias Carrier.Secrets
  alias Carrier.Secrets.DataSource

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:step, "step-1")
      |> assign(:source, nil)
      |> assign(:conn_info, %{})
      |> assign(:changeset, nil)
      |> assign(:error, nil)

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

    params_module =
      case source do
        :postgres ->
          ConnInfoParams.Postgres

        :mysql ->
          ConnInfoParams.MySQL
      end

    conn_info = struct(params_module)

    socket =
      socket
      |> assign(:step, "step-2")
      |> assign(:source, source)
      |> assign(:conn_info, conn_info)
      |> assign(:changeset, params_module.changeset(conn_info))

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_conn_info", %{"conn_info" => conn_info_params}, socket) do
    conn_info = socket.assigns.conn_info

    changeset =
      conn_info
      |> conn_info.__struct__.changeset(conn_info_params)
      |> Map.put(:action, :validate)

    conn_info = Ecto.Changeset.apply_changes(changeset)

    socket = socket |> assign(:conn_info, conn_info) |> assign(:changeset, changeset)

    socket =
      case changeset.valid? do
        true ->
          conn_info_params = %{
            org_id: socket.assigns.org_id,
            name: conn_info_params["name"],
            source: socket.assigns.source,
            hostname: conn_info_params["hostname"],
            port: conn_info_params["port"],
            username: conn_info_params["username"],
            password: conn_info_params["password"],
            database: conn_info_params["database"]
          }

          socket |> create_conn_info(conn_info_params)

        false ->
          socket
      end

    {:noreply, socket}
  end

  defp create_conn_info(socket, params) do
    case do_create_conn_info(params) do
      {:ok, %DataSource{}} ->
        socket
        |> push_redirect(to: Routes.report_new_path(socket, :new))

      {:error, reason} ->
        socket
        |> assign(:error, reason)
        |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(inspect(e))

      socket |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
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
    Secrets.create_data_source(%{
      org_id: org_id,
      name: name,
      source: source,
      conn_info: %{
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database
      }
    })
  end
end
