defmodule CarrierWeb.App.ReportLive.New2.AmplitudeDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias CarrierWeb.App.ReportLive.New2.{DataSourceInfoParams, AmplitudeParams, AmplitudeDashboard}
  alias Carrier.Data.Source.Amplitude
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:amplitude_form, AmplitudeParams.to_form(%{dashboards: [%{}]}))

    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{data_source: %DataSource{} = _data_source, data_source_info: data_source_info} =
          assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)

    socket =
      case data_source_info do
        nil ->
          socket

        %{params: params} ->
          socket
          |> assign(:amplitude_form, AmplitudeParams.to_form(params |> Params.struct_to_map()))
      end

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="2. 대시보드 데이터 설정" />
          </div>

          <div class="max-w-md">
            <.simple_form for={@amplitude_form} phx-target={@myself} phx-change="validate_form">
              <.inputs_for :let={dashboard} field={@amplitude_form[:dashboards]}>
                <.field_adder_hidden for={dashboard} name="amplitude[dashboard_order][]" />
                <.input
                  type="text"
                  field={dashboard[:url]}
                  label="대시보드 URL"
                  label_align={:left}
                />
                <.live_component
                  module={AmplitudeDashboard}
                  id={dashboard.id}
                  data_source={@data_source}
                  dashboard={struct(Amplitude.Dashboard, dashboard |> Params.to_map())}
                />
                <.field_remover
                  for={dashboard}
                  name="amplitude[dashboard_delete][]"
                  label="대시보드 삭제"
                />
                <hr />
              </.inputs_for>
              <.field_adder name="amplitude[dashboard_order][]" label="대시보드 추가" />
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("validate_form", %{"amplitude" => params}, socket) do
    amplitude_form = AmplitudeParams.to_form(params)

    socket =
      socket
      |> assign(:amplitude_form, amplitude_form)

    validate_and_send_data_source_info_form(socket)

    {:noreply, socket}
  end

  defp validate_and_send_data_source_info_form(socket) do
    params = socket.assigns.amplitude_form |> Params.to_map()

    data_source_info_input = %{
      data_source_id: socket.assigns.data_source.id,
      source: :amplitude,
      params: params
    }

    data_source_info_form = DataSourceInfoParams.to_form(data_source_info_input)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
