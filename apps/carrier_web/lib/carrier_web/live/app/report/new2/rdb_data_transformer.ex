defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Data}
  alias CarrierWeb.App.ReportLive.New2.DataSourceInfoParams
  alias Doumi.Phoenix.Params
  alias Carrier.Core.TimezoneHelper

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, "")
      |> assign(:query_errors, [])
      |> assign(:query_result, nil)
      |> assign(:timezone, TimezoneHelper.get_timezone())

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
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="쿼리 입력하기" />
            <p class="mt-2">☝️ 기준이 되는 날짜 컬럼과 보고 싶은 지표 컬럼(최대 3개)을 쿼리해주세요.</p>
          </div>
          <div>
            <.simple_form
              for={%{}}
              phx-target={@myself}
              phx-change="update_query"
              phx-submit="run_query"
            >
              <.input
                type="textarea"
                name="sql_template"
                value={@sql_template}
                errors={@query_errors}
              />
              <.button class="mt-2">쿼리 실행</.button>
            </.simple_form>
          </div>
          <div class="mt-6">
            <.card_title title="쿼리 결과 데이터" />
            <p :if={!@query_result} class="mt-2">쿼리를 실행해주세요.</p>
            <.table :if={@query_result} id="query_result" rows={@query_result.data |> Enum.reverse()}>
              <:col :let={row} :for={column <- @query_result.columns} label={column}>
                <%= row[column] %>
              </:col>
            </.table>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("update_query", %{"sql_template" => sql_template}, socket) do
    socket = socket |> assign(:sql_template, sql_template)

    {:noreply, socket}
  end

  @impl true
  def handle_event("run_query", %{"sql_template" => sql_template}, socket) do
    socket =
      Source.RDB.load_raw_data(socket.assigns.data_source, %{
        sql_template: sql_template,
        datetime: DateTime.utc_now(),
        timezone: socket.assigns.timezone,
        period_days: 28,
        over_days: 7,
        window_days: 7
      })
      |> case do
        {:ok, query_result} ->
          socket
          |> assign(:query_result, query_result)

        {:error, reason} ->
          socket
          |> assign(:query_errors, [reason])
      end

    {:noreply, socket}
  end

  defp validate_and_send_data_source_info_form(socket) do
    %DataSource{id: data_source_id, source: source} = socket.assigns.data_source

    data_source_info_input = %{
      data_source_id: data_source_id,
      source: source,
      params: %{}
    }

    data_source_info_form =
      Params.to_form(%DataSourceInfoParams{}, data_source_info_input, as: :data_source_info)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
