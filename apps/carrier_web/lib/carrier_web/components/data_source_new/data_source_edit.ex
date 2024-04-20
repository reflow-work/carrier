defmodule CarrierWeb.Components.DataSourceEdit do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  use Carrier.Setting
  require Logger
  alias CarrierWeb.Components.DataSourceNew.ConnInfoParams
  # TODO: move to CarrierWeb
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:datasource, nil)
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    %{
      org_id: org_id,
      name: name,
      source: source,
      conn_info: conn_info_struct
    } = socket.assigns.data_source

    data_source_module =
      case source do
        :postgres -> ConnInfoParams.Postgres
        :mysql -> ConnInfoParams.MySQL
        :bigquery -> ConnInfoParams.BigQuery
        :athena -> ConnInfoParams.Athena
        :tableau -> ConnInfoParams.Tableau
        :redash -> ConnInfoParams.Redash
        :amplitude -> ConnInfoParams.Amplitude
      end

    form =
      Params.to_form(
        struct(
          data_source_module,
          %{
            org_id: org_id,
            name: name,
            source: source,
            conn_info:
              struct(
                Module.concat(data_source_module, :ConnInfo),
                conn_info_struct.info
                |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
              )
          }
        ),
        %{},
        as: :data_source,
        validate: false
      )

    socket =
      socket
      |> assign(org_id: org_id)
      |> assign(form: form)
      |> assign(source: :tableau, data_source_module: data_source_module)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-12">
        <div class="col-span-6">
          <div class="rounded-md">
            <div>
              <div class="mt-8">
                <div :if={@source == :tableau} class="callout mb-6 max-w-fit">
                  <div class="callout-icon">
                    <Icon.alert_circle class="w-4 h-4 mt-0.5" />
                  </div>
                  <div>
                    Tableau의 각 정보를 확인하는 방법은 <a
                      href={Const.get(:tableau_guide_url)}
                      target="_blank"
                      class="underline text-sky-500"
                    >가이드</a>에서 보실 수 있습니다.
                  </div>
                </div>

                <.simple_form
                  for={@form}
                  phx-target={@myself}
                  phx-change="validate_data_source"
                  phx-submit="edit_data_source"
                >
                  <.input
                    type="hidden"
                    field={@form[:name]}
                    label="데이터 소스 이름"
                    placeholder="데이터 마트"
                    autofocus
                    class="max-w-xs"
                    value={@data_source.name}
                  />

                  <CarrierWeb.Components.DataSourceNew.Components.source_inputs
                    source={@source}
                    form={@form}
                  />

                  <:actions>
                    <.button
                      type="submit"
                      disabled={!@form.source.valid?}
                      phx-disable-with="연결중"
                    >
                      연결하기
                    </.button>
                  </:actions>
                  <.error :if={@error}><%= @error %></.error>
                </.simple_form>
              </div>
            </div>
          </div>
        </div>

        <div class="col-span-6">
          <div class="callout mt-2">
            <div class="callout-icon">
              <Icon.alert_circle class="w-4 h-4 mt-0.5" />
            </div>
            <div>데이터 소스 연동 정보를 모르시는 경우에는 개발자에게 <b>2. 연결 정보 설정</b>에 보이는 입력폼을 캡쳐하여 필요한 정보를 요청해주세요.</div>
          </div>
          <div class="callout mt-2">
            <div class="callout-icon">
              <Icon.alert_circle class="w-4 h-4 mt-0.5" />
            </div>
            <div>데이터 소스에 방화벽이 설정되어 있는 경우 아래 IP를 화이트 리스트에 추가해주세요.<br />
              <b>IP: 15.165.126.27</b></div>
          </div>
        </div>
      </div>
    </div>
    """
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
  def handle_event("edit_data_source", %{"data_source" => data_source_inputs}, socket) do
    data_source_params =
      socket
      |> validate_form(data_source_inputs)
      |> Params.to_map()

    socket =
      socket
      |> edit_data_source(data_source_params)

    {:noreply, socket}
  end

  defp edit_data_source(socket, %{conn_info: info}) do
    case Integrations.update_conn_info_of_data_source(socket.assigns.data_source.id, %{info: info}) do
      {:ok, %DataSource{} = data_source} ->
        socket.assigns.onsuccess.(data_source)

        socket

      {:error, {:invalid_conn_info, reason}} when is_binary(reason) ->
        Logger.error(reason)

        socket
        |> assign(:error, reason)
        |> push_flash(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

      {:error, {:invalid_conn_info, reason}} ->
        Logger.error(inspect(reason))

        socket
        |> assign(:error, inspect(reason))
        |> push_flash(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

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
        |> push_flash(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))

      {:error, reason} ->
        Logger.error(inspect(reason))

        socket
        |> assign(:error, inspect(reason))
        |> push_flash(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      socket
      |> assign(:error, Exception.message(e))
      |> push_flash(:error, "데이터 소스 연동에 실패하였습니다.", timeout: :timer.seconds(3))
  end

  defp validate_form(socket, data_source_inputs) do
    data_source_module = socket.assigns.data_source_module

    data_source_params =
      data_source_inputs
      |> Map.merge(%{"org_id" => socket.assigns.org_id})

    Params.to_form(struct(data_source_module), data_source_params, as: :data_source)
  end
end
