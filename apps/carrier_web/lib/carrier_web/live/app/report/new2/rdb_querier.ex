defmodule CarrierWeb.App.ReportLive.New2.RDBQuerier do
  use CarrierWeb, :live_component
  use Carrier.Data
  alias CarrierWeb.Components.QueryChecker
  alias Carrier.Core.TimezoneHelper

  @max_period_days 365
  @max_over_days 28
  @max_window_days 7

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, nil)
      |> assign(:query_errors, [])
      |> assign(:query_result, nil)
      |> assign(:query_validations, %{contains_start: true, contains_end: true})
      |> assign(:timezone, TimezoneHelper.get_timezone())

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    socket =
      case socket.assigns.sql_template do
        nil -> socket
        _sql_template -> socket |> run_query()
      end

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
              phx-change="validate_query"
              phx-submit="run_query"
            >
              <div class="flex-col gap-2 sm:grid sm:grid-cols-7 sm:gap-2 pt-2">
                <div class="sm:col-span-4">
                  <.input
                    type="textarea"
                    name="sql_template"
                    class="h-full"
                    input_class="mt-0"
                    value={@sql_template}
                    errors={@query_errors}
                  />
                </div>
                <div class="w-full px-2 sm:col-span-3 text-sm">
                  <QueryChecker.checker checked={@query_validations.contains_start}>
                    <b>기간 시작 조건</b>에 실제 날짜가 아닌 <code class="code">{{start}}</code>를 넣어주세요.
                  </QueryChecker.checker>

                  <QueryChecker.checker class="mt-2" checked={@query_validations.contains_end}>
                    <b>기간 종료 조건</b>에 실제 날짜가 아닌 <code class="code">{{end}}</code>를 넣어주세요.
                  </QueryChecker.checker>

                  <div class="bg-yellow-50 rounded p-3 mt-3">
                    <b>📌 Check point</b>

                    <p class="mt-2">
                      - SELECT문의 첫 번째 컬럼에 <b>DATE 타입</b>의 기준이 되는 날짜 컬럼을 넣어주세요.
                    </p>

                    <p class="mt-2">
                      - SELECT문의 두 번째 컬럼부터는 <b>지표 컬럼</b>을 넣어주세요.
                    </p>

                    <p class="mt-2">
                      - <code class="code">AS "표시할 이름"</code>을 통해 지정한 지표 컬럼의 이름대로 레포트 제목이 생성됩니다.
                    </p>

                    <p class="mt-2">
                      - 집계된 데이터가 담긴 테이블이 아닌 경우 기준이 되는 날짜로 GROUP BY한 집계 쿼리를 작성해주세요.
                    </p>
                  </div>
                </div>
              </div>
              <.button class="mt-2" disabled={run_query_disabled?(@sql_template, @query_validations)}>
                쿼리 실행
              </.button>
            </.simple_form>
          </div>
          <div class="mt-6">
            <.card_title title="쿼리 결과 데이터" />
            <p :if={!@query_result} class="mt-2">쿼리를 실행해주세요.</p>
            <div :if={@query_result} class="h-96 overflow-auto">
              <.table id="query_result" rows={@query_result.data |> Enum.reverse()}>
                <:col :let={row} :for={column <- @query_result.columns} label={column}>
                  <%= row[column] %>
                </:col>
              </.table>
            </div>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("validate_query", %{"sql_template" => sql_template}, socket) do
    socket =
      socket
      |> assign(:sql_template, sql_template)
      |> assign(:query_validations, %{
        contains_start: sql_template |> String.contains?("{{start}}"),
        contains_end: sql_template |> String.contains?("{{end}}")
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("run_query", %{"sql_template" => sql_template}, socket) do
    socket =
      socket
      |> assign(:sql_template, sql_template)
      |> run_query()

    {:noreply, socket}
  end

  defp run_query(socket) do
    Source.RDBOld.load_raw_data(
      %{
        data_source_info: %{
          sql_template: socket.assigns.sql_template,
          period: @max_period_days,
          window_size: @max_window_days,
          comparing_period: @max_over_days
        },
        datetime: DateTime.utc_now(),
        timezone: socket.assigns.timezone
      },
      socket.assigns.data_source
    )
    |> case do
      {:ok, query_result} ->
        socket.assigns.onchange.(socket.assigns.sql_template, query_result)

        socket
        |> assign(:query_result, query_result)

      {:error, reason} ->
        socket
        |> assign(:query_errors, [reason])
    end
  end

  defp run_query_disabled?(sql_template, query_validations) do
    sql_template |> Blankable.blank?() || query_validations |> Map.values() |> Enum.all?(&(!&1))
  end
end
