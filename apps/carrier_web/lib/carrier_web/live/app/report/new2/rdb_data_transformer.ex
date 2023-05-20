defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Data}
  alias CarrierWeb.App.ReportLive.New2.{DataSourceInfoParams, RDBParams}
  alias CarrierWeb.App.ReportLive.New2.RDBQuerier
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, "")
      |> assign(:query_result, nil)
      |> assign(:rdb_form, RDBParams.to_form(%{charts: [%{}]}))

    {:ok, socket}
  end

  # init
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={RDBQuerier}
        id="rdb_querier"
        data_source={@data_source}
        onchange={
          fn sql_template, query_result ->
            send_update(__MODULE__, id: @id, sql_template: sql_template, query_result: query_result)
          end
        }
      />
      <.card_container :if={@query_result}>
        <.card>
          <.card_title title="차트 설정하기" />
          <div>
            <.simple_form for={@rdb_form} phx-target={@myself} phx-change="validate_rdb">
              <.inputs_for :let={chart} field={@rdb_form[:charts]}>
                <div class="flex space-x-8">
                  <div class="flex-1 max-w-md">
                    <.input
                      type="text"
                      field={chart[:name]}
                      label="차트 이름"
                      label_align={:left}
                    />
                  </div>
                  <div class="flex-1">
                    미리보기
                  </div>
                </div>
              </.inputs_for>
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("validate_rdb", params, socket) do
    rdb_form = validate_rdb(params, socket)

    socket =
      socket
      |> assign(:rdb_form, rdb_form)

    {:noreply, socket}
  end

  defp validate_rdb(params, socket) do
    params =
      socket.assigns.rdb_form
      |> Params.to_params(
        params
        |> Map.merge(%{"sql_template" => socket.assigns.sql_template, "unit" => "day"})
      )

    RDBParams.to_form(params)
  end

  defp validate_and_send_data_source_info_form(socket) do
    %DataSource{id: data_source_id, source: source} = socket.assigns.data_source

    params = socket.assigns.rdb_form |> Params.to_map()

    data_source_info_input = %{
      data_source_id: data_source_id,
      source: source,
      params: params
    }

    data_source_info_form = DataSourceInfoParams.to_form(data_source_info_input)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
