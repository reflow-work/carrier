defmodule CarrierWeb.App.DataSourceLive.New do
  use CarrierWeb, :live_view
  use Carrier.Integrations
  use Carrier.Setting
  alias CarrierWeb.Components.Icon
  alias __MODULE__.ConnInfoParams
  alias __MODULE__.Components
  # TODO: move to CarrierWeb
  alias Doumi.Phoenix.Params

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:step, "step-1")
      |> assign(:source, nil)
      |> assign(:data_source_module, nil)
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
        :postgres -> ConnInfoParams.Postgres
        :mysql -> ConnInfoParams.MySQL
        :bigquery -> ConnInfoParams.BigQuery
        :athena -> ConnInfoParams.Athena
        :tableau -> ConnInfoParams.Tableau
      end

    form =
      Params.to_form(
        struct(data_source_module),
        data_source_module.init_attrs(),
        as: :data_source,
        validate: false
      )

    socket =
      socket
      |> assign(:step, "step-2")
      |> assign(:source, source)
      |> assign(:data_source_module, data_source_module)
      |> assign(:form, form)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_data_source", %{"data_source" => data_source_inputs}, socket) do
    form =
      socket
      |> validate_form(data_source_inputs)

    socket =
      socket
      |> assign(:form, form)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_data_source", %{"data_source" => data_source_inputs}, socket) do
    data_source_params =
      socket
      |> validate_form(data_source_inputs)
      |> Params.to_map()

    socket =
      socket
      |> create_data_source(data_source_params)

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

        data_source_inputs =
          socket.assigns.form
          |> Params.to_params(data_source_inputs)

        form =
          socket
          |> validate_form(data_source_inputs)

        socket =
          socket
          |> assign(:form, form)
          |> assign(:file_name, file_name)

        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  defp create_data_source(socket, params) do
    case do_create_data_source(params) do
      {:ok, %DataSource{}} ->
        socket
        |> push_navigate(to: ~p"/app/reports/new")

      {:error, {:invalid_conn_info, reason}} ->
        Logger.error(inspect(reason))

        socket
        |> assign(:error, inspect(reason))
        |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

      # TODO: better error handling
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error(inspect(changeset))

        [{field, [reason | _]} | _] =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)
          |> Enum.to_list()

        socket
        |> assign(:error, "#{field} #{reason}")
        |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

      {:error, reason} ->
        Logger.error(inspect(reason))

        socket
        |> assign(:error, inspect(reason))
        |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(inspect(e))

      socket |> put_flash_for(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
  end

  defp do_create_data_source(params) do
    Integrations.create_data_source(params)
  end

  defp validate_form(socket, data_source_inputs) do
    data_source_module = socket.assigns.data_source_module

    data_source_params =
      data_source_inputs
      |> Map.merge(%{"org_id" => socket.assigns.org.org_id})

    Params.to_form(struct(data_source_module), data_source_params, as: :data_source)
  end

  defp data_sources() do
    [
      {:mysql, "MySQL", "logo-mysql.png"},
      {:postgres, "PostgreSQL", "logo-postgresql.png"},
      {:bigquery, "BigQuery", "logo-bigquery.png"},
      {:athena, "Athena", "logo-athena.png"},
      {:tableau, "Tableau Cloud", "logo-tableau.png"}
    ]
    |> then(fn data_sources ->
      case Setting.get_feature_flag_value("data_source_athena") do
        true -> data_sources
        false -> Enum.reject(data_sources, fn {source, _, _} -> source == :athena end)
      end
    end)
    |> then(fn data_sources ->
      case Setting.get_feature_flag_value("data_source_tableau") do
        true -> data_sources
        false -> Enum.reject(data_sources, fn {source, _, _} -> source == :tableau end)
      end
    end)
  end
end
