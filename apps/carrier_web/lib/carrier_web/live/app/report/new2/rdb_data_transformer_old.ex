defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformerOld do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Data}
  alias CarrierWeb.App.ReportLive.New2.RDBParamsOld
  alias CarrierWeb.App.ReportLive.New2.RDBQuerier
  alias CarrierWeb.Components.SlackImgMetaData
  alias Carrier.Data.QueryData
  alias Carrier.Core.{TimezoneHelper, DateHelper}
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, nil)
      |> assign(:query_result, nil)
      |> assign(:period, 28)
      |> assign(:comparing_period, 28)
      |> assign(:rdb_form, RDBParamsOld.to_form(%{window_size: 1, columns: []}, validate: false))
      |> assign(:timezone, TimezoneHelper.get_timezone())

    {:ok, socket}
  end

  @impl true
  def update(%{sql_template: _sql_template, query_result: _query_result} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> update_columns()
      |> assign_query_result_by_columns()

    validate_and_send_data_source_info_form(socket)

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
      <.card_container :if={@query_result} class="flex flex-col gap-4 lg:flex-row">
        <.card class="basis-96">
          <.card_title title="차트 설정하기" />
          <div>
            <.simple_form for={@rdb_form} phx-target={@myself} phx-change="validate_rdb">
              <.input
                type="checkgroup"
                field={@rdb_form[:columns]}
                multiple={true}
                label="지표 선택"
                options={data_columns(@query_result)}
              />
              <.input
                type="radio-group"
                field={@rdb_form[:window_size]}
                label="그래프 값 옵션"
                options={[{"당일 지표", 1}, {"7일 이동합계", 7}]}
              />
            </.simple_form>
          </div>
        </.card>
        <.card class="flex-1">
          <.card_title title="차트 미리보기" />
          <div class="space-y-3">
            <div :for={column <- @rdb_form[:columns].value}>
              <section class="space-y-3 bg-slackImgLightGrey p-4">
                <p class="font-bold text-base-dark text-sm">
                  <%= report_title(column, @timezone) %>
                </p>
                <div class="grid grid-cols-2 py-4 px-5 rounded-lg shadow-slackImgSection bg-white divide-x-2 divide-slackImgLightGrey">
                  <section>
                    <h4 class="text-xs font-bold text-slackImgGrey">어제</h4>
                    <p class="text-xl font-bold mt-2">
                      <%= format_number(
                        @query_result_by_columns[column].meta.current_period_last_tick_raw
                      ) %>
                    </p>
                    <div class="flex space-x-2 mt-1">
                      <SlackImgMetaData.card
                        diff_value_raw={
                          @query_result_by_columns[column].meta.diff_between_period_raws
                        }
                        diff_value_percentage={
                          @query_result_by_columns[column].meta.diff_between_period_raws_in_percentage
                        }
                      />
                    </div>
                  </section>
                  <section class="pl-5">
                    <h4 class="text-xs font-bold text-slackImgGrey">최근 7일 합계</h4>
                    <p class="text-xl font-bold mt-2">
                      <%= format_number(@query_result_by_columns[column].meta.current_period_sum) %>
                    </p>
                    <div class="flex space-x-2 mt-1">
                      <SlackImgMetaData.card
                        diff_value_raw={
                          @query_result_by_columns[column].meta.diff_between_period_sums
                        }
                        diff_value_percentage={
                          @query_result_by_columns[column].meta.diff_between_period_sums_in_percentage
                        }
                      />
                    </div>
                  </section>
                </div>
                <section
                  id={"chart-container-#{@query_result_by_columns[column].meta.label}"}
                  phx-update="ignore"
                  class="h-[250px]"
                >
                  <canvas
                    id={"chart-#{@query_result_by_columns[column].meta.label}"}
                    class="rounded-lg shadow-slackImgSection"
                    phx-hook="Chart"
                  >
                  </canvas>
                </section>
              </section>
            </div>
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

    validate_and_send_data_source_info_form(socket)

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

  defp assign_query_result_by_columns(socket) do
    %{columns: [_date_column | data_columns] = columns, data: data} = socket.assigns.query_result
    window_size = socket.assigns.rdb_form[:window_size].value

    {:ok, analyzed_data} =
      QueryData.analyze(data, %{
        columns: columns,
        period: socket.assigns.period,
        window_size: window_size,
        comparing_period: socket.assigns.comparing_period
      })

    parsed_data =
      QueryData.refine_data_based_on_columns(
        %{columns: columns, data: analyzed_data},
        data_columns,
        window_size
      )

    socket
    |> assign(:query_result_by_columns, parsed_data)
    |> add_draw_chart_events()
  end

  defp update_columns(socket) do
    rdb_form =
      socket.assigns.rdb_form
      |> Params.to_params(%{
        "data_source_id" => socket.assigns.data_source.id,
        "source" => socket.assigns.data_source.source,
        "sql_template" => socket.assigns.sql_template,
        "period" => socket.assigns.period,
        "comparing_period" => socket.assigns.comparing_period,
        "columns" => data_columns(socket.assigns.query_result)
      })
      |> RDBParamsOld.to_form()

    socket
    |> assign(:rdb_form, rdb_form)
  end

  defp add_draw_chart_events(socket) do
    columns = socket.assigns.rdb_form[:columns].value

    socket.assigns.query_result_by_columns
    |> Enum.filter(fn {k, _v} -> k in columns end)
    |> Enum.reduce(socket, fn {k, v}, acc ->
      push_event(acc, "input_data_#{k}", v)
    end)
  end

  defp data_columns(%{columns: [_date_column | data_columns]} = _query_result) do
    data_columns
  end

  defp report_title(title, timezone) do
    "📊 #{current_datetime!(timezone) |> DateHelper.safe_format_date()} - #{title}"
  end
end
