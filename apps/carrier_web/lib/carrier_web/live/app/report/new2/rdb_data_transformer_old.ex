defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformerOld do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Data}
  alias CarrierWeb.App.ReportLive.New2.RDBParamsOld
  alias CarrierWeb.App.ReportLive.New2.RDBQuerier

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, "")
      |> assign(:query_result, nil)
      |> assign(:period, 28)
      |> assign(:comparing_period, 28)
      |> assign(:rdb_form, RDBParamsOld.to_form(%{}, validate: false))

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
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("validate_rdb", %{"rdb" => params}, socket) do
    rdb_form = validate_rdb(params, socket)

    socket =
      socket
      |> assign(:rdb_form, rdb_form)

    {:noreply, socket}
  end

  defp validate_rdb(params, socket) do
    params =
      params
      |> Map.merge(%{
        "data_source_id" => socket.assigns.data_source.id,
        "source" => socket.assigns.data_source.source,
        "sql_template" => socket.assigns.sql_template,
        "period" => socket.assigns.period,
        "comparing_period" => socket.assigns.comparing_period
      })

    RDBParamsOld.to_form(params)
  end

  defp validate_and_send_data_source_info_form(socket) do
    send(self(), {:update, {:data_source_info_form, socket.assigns.rdb_form}})
  end
end
