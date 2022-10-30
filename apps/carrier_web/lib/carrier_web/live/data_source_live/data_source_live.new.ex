defmodule CarrierWeb.DataSourceLive.New do
  use CarrierWeb, :live_view
  use CarrierWeb.Params
  alias CarrierWeb.Components.Icon
  alias CarrierWeb.DataSourceLive.ConnInfoParams
  alias Carrier.Secrets
  alias Carrier.Secrets.DataSource

  on_mount(CarrierWeb.NoDataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:step, "step-1")
      |> assign(:source, nil)
      |> assign(:conn_info_module, nil)
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

    conn_info_module =
      case source do
        :postgres ->
          ConnInfoParams.Postgres

        :mysql ->
          ConnInfoParams.MySQL
      end

    socket =
      socket
      |> assign(:step, "step-2")
      |> assign(:source, source)
      |> assign(:conn_info_module, conn_info_module)
      |> assign(:changeset, conn_info_module.changeset(conn_info_module.init_attrs()))

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_conn_info", %{"conn_info" => conn_info_inputs}, socket) do
    changeset = validate_changeset(socket, conn_info_inputs)

    socket = socket |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_conn_info", %{"conn_info" => conn_info_inputs}, socket) do
    changeset = validate_changeset(socket, conn_info_inputs)
    conn_info_params = apply_changes(changeset)

    socket = socket |> create_conn_info(conn_info_params)

    {:noreply, socket}
  end

  defp create_conn_info(socket, params) do
    case do_create_conn_info(params) do
      {:ok, %DataSource{}} ->
        socket
        |> push_navigate(to: Routes.report_new_path(socket, :new))

      {:error, reason} ->
        Logger.error(inspect(reason))

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
         database: database,
         ssl: ssl
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
        database: database,
        ssl: ssl
      }
    })
  end

  defp validate_changeset(socket, conn_info_inputs) do
    conn_info_module = socket.assigns.conn_info_module

    params =
      conn_info_inputs
      |> Map.merge(%{
        "org_id" => socket.assigns.org_id
      })

    _changeset =
      conn_info_module.changeset(params)
      |> set_action(:validate)
  end
end
