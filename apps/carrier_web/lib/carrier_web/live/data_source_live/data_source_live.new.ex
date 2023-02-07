defmodule CarrierWeb.DataSourceLive.New do
  use CarrierWeb, :live_view
  use CarrierWeb.Params
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
      |> assign(:data_source_module, nil)
      |> assign(:changeset, nil)
      |> assign(:error, nil)
      |> assign(:file_name, nil)
      |> allow_upload(:credentials,
        accept: ~w(.json),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("change_step", %{"step" => step}, socket) do
    socket =
      case socket.assigns.source do
        nil -> socket
        _ -> socket |> assign(:step, step)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_source", %{"source" => source_str}, socket) do
    source = String.to_existing_atom(source_str)

    socket =
      socket
      |> log_event("click_data_source_type", %{
        page_name: "data_source_new",
        type: source_str
      })

    data_source_module =
      case source do
        :postgres ->
          ConnInfoParams.Postgres

        :mysql ->
          ConnInfoParams.MySQL

        :bigquery ->
          ConnInfoParams.BigQuery
      end

    socket =
      socket
      |> assign(:step, "step-2")
      |> assign(:source, source)
      |> assign(:data_source_module, data_source_module)
      |> assign(:changeset, data_source_module.changeset(data_source_module.init_attrs()))

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_data_source", %{"data_source" => data_source_inputs}, socket) do
    changeset = validate_changeset(socket, data_source_inputs)

    socket = socket |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_data_source", %{"data_source" => data_source_inputs}, socket) do
    data_source_params =
      validate_changeset(socket, data_source_inputs)
      |> Params.to_map()

    socket = socket |> create_data_source(data_source_params)

    {:noreply, socket}
  end

  defp handle_progress(:credentials, entry, socket) do
    case entry.done? do
      true ->
        [{file_name, data_source_inputs}] =
          socket
          |> consume_uploaded_entries(:credentials, fn %{path: path}, entry ->
            file_name = entry.client_name

            credentials_json = path |> File.read!()
            %{"project_id" => project_id} = credentials_json |> Jason.decode!()

            {:ok,
             {file_name,
              %{
                "conn_info" => %{
                  "project_id" => project_id,
                  "credentials_json" => credentials_json
                }
              }}}
          end)

        # hard coding
        name = socket.assigns.changeset.changes[:name]
        data_source_inputs = Map.put(data_source_inputs, "name", name)

        changeset = validate_changeset(socket, data_source_inputs)

        socket = socket |> assign(:changeset, changeset) |> assign(:file_name, file_name)

        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  defp create_data_source(socket, params) do
    case do_create_data_source(params) do
      {:ok, %DataSource{}} ->
        socket
        |> push_navigate(to: Routes.report_new_path(socket, :new))

      {:error, {:invalid_conn_info, reason}} ->
        Logger.error(inspect(reason))

        socket
        |> assign(:error, reason)
        |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

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

  defp do_create_data_source(params) do
    Secrets.create_data_source(params)
  end

  defp validate_changeset(socket, data_source_inputs) do
    data_source_module = socket.assigns.data_source_module

    params =
      data_source_inputs
      |> Map.merge(%{
        "org_id" => socket.assigns.org_id
      })

    _changeset =
      data_source_module.changeset(params)
      |> Params.set_action(:validate)
  end
end
