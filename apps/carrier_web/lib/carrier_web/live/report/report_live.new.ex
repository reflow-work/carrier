defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  use CarrierWeb.Params
  alias Carrier.Data.QueryData
  alias Carrier.Reports
  alias Carrier.Reports.Report
  alias Carrier.Noti
  alias Carrier.External.Slack
  alias Carrier.External.Aws
  alias Carrier.Core.{TimeHelper, Traversable, MapHelper}
  alias CarrierWeb.Components.Empty
  alias CarrierWeb.ReportLive.New.ReportParams

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @sample_sql_template """
  SELECT
    DATE([기준이 되는 날짜 컬럼]),
    SUM([보고 싶은 지표 컬럼1]) AS [컬럼1 이름],
    SUM([보고 싶은 지표 컬럼2]) AS [컬럼2 이름],
    SUM([보고 싶은 지표 컬럼3]) AS [컬럼3 이름]
  FROM [테이블 이름]
  WHERE DATE([기준이 되는 날짜 컬럼]) >= {{start}}
    AND DATE([기준이 되는 날짜 컬럼]) < {{end}}
  GROUP BY 1
  """
  @sql_template_by_maker """
  SELECT
    DATE(<%= date_column %>),
    <%= aggregation %>(<%= value_column %>) AS "<%= if value_column_name != "", do: value_column_name, else: value_column %>"
  FROM <%= table_name %>
  WHERE <%= date_column %> >= {{start}}
    AND <%= date_column %> < {{end}}
  GROUP BY 1
  """

  @impl true
  def mount(_params, _session, socket) do
    {:ok, channels} =
      Slack.list_conversations(socket.assigns.integration.conn_info.info["bot_token"])

    channel_options = channels |> Enum.map(fn %{id: id, name: name} -> {name, id} end)

    socket =
      socket
      |> assign(
        tables: [],
        date_columns: [],
        value_columns: [],
        aggregations: ["SUM", "AVG", "COUNT", "MAX", "MIN"]
      )
      |> assign(%{
        sample_sql_template: @sample_sql_template,
        sql_template: @sample_sql_template,
        query_error_message: nil
      })
      |> assign(:data_loaded, false)
      |> assign(%{
        preview: nil,
        show_full_preview_data: false
      })
      |> assign(:query_result_by_columns, nil)
      |> assign(:selected_columns, [])
      |> assign(:channels, channel_options)
      |> assign(:hours, 0..23 |> Enum.map(&{"매일 #{&1}시", &1}))
      |> assign(:is_loading_slack_channels, false)
      |> assign(:report_changeset, ReportParams.changeset(ReportParams.init_attrs()))
      |> assign(:query_validations, %{contains_start: true, contains_end: true})

    {:ok, socket}
  end

  @impl true
  def handle_event("open_query_maker", _params, socket) do
    socket =
      QueryData.fetch_table_names(%{
        org_id: socket.assigns.org_id,
        data_source_id: socket.assigns.data_source.id
      })
      |> case do
        {:ok, tables} ->
          socket
          |> assign(:tables, tables)
          |> push_event("js-exec", %{to: "#query-maker", attr: "data-show-modal"})

        {:error, _} ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_table", params, socket) do
    %{"query_maker_form" => %{"table" => table}} = params

    socket = load_columns(socket, table)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_query", params, socket) do
    %{
      "query_maker_form" => %{
        "aggregation" => aggregation,
        "value_column" => value_column,
        "date_column" => date_column,
        "value_column_name" => value_column_name,
        "table" => table
      }
    } = params

    value =
      @sql_template_by_maker
      |> EEx.eval_string(
        aggregation: aggregation,
        date_column: date_column,
        value_column: value_column,
        value_column_name: value_column_name,
        table_name: table
      )

    socket =
      socket
      |> assign(:sql_template, value)
      |> push_event("js-exec", %{to: "#query-maker", attr: "data-hide-modal"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket =
      assign(socket, :query_validations, %{
        contains_start: sql_template |> String.contains?("{{start}}"),
        contains_end: sql_template |> String.contains?("{{end}}")
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("run_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket =
      socket
      |> assign(:sql_template, sql_template)

    socket =
      QueryData.query(%{
        org_id: socket.assigns.org_id,
        data_source_id: socket.assigns.data_source.id,
        sql_template: sql_template,
        datetime: DateTime.utc_now(),
        timezone: socket.assigns.timezone,
        period: 28,
        window_size: 7,
        comparing_period: 7
      })
      |> case do
        {:ok, raw_data} ->
          preview = QueryData.format_data_for_preview(raw_data)
          parsed_data = QueryData.refine_data_based_on_columns(raw_data, raw_data.columns)
          columns = parsed_data |> Map.keys()

          socket
          |> assign(:data_loaded, true)
          |> assign(:query_error_message, nil)
          |> assign(:preview, preview)
          |> assign(:query_result_by_columns, parsed_data)
          |> assign(:columns, columns)
          |> assign(:selected_columns, columns)
          |> add_draw_chart_events(parsed_data, columns)
          |> assign(
            :report_changeset,
            ReportParams.changeset(
              ReportParams.init_attrs(%{
                "org_id" => socket.assigns.org_id,
                "user_id" => socket.assigns.user.id,
                "integration_info" => %{
                  "integration_id" => socket.assigns.integration.id
                },
                "data_source_info" => %{
                  "data_source_id" => socket.assigns.data_source.id,
                  "sql_template" => sql_template,
                  "timezone" => socket.assigns.timezone,
                  "period" => 28,
                  "window_size" => 7,
                  "comparing_period" => 7,
                  "columns" => columns
                }
              })
            )
          )

        {:error, error} ->
          message =
            case error do
              :not_number_type_after_first_column -> "첫 번째 컬럼 이후에는 숫자 타입의 컬럼만 사용할 수 있습니다."
              :first_column_is_not_date_type -> "첫 번째 컬럼은 Date 타입이어야 합니다."
              :sql_not_a_select_query -> "SELECT 문으로 시작되어야 합니다."
              :query_failed -> "쿼리 실행에 실패했습니다."
              {:query_error, message} -> message
              error -> inspect(error)
            end

          socket |> assign(:query_error_message, "쿼리 실행 중 오류: #{message}")
      end

    {:noreply, socket}
  end

  def handle_event("select_window_size", %{"value" => window_size_str}, socket) do
    window_size = window_size_str |> convert_window_size()

    socket =
      QueryData.query(%{
        org_id: socket.assigns.org_id,
        data_source_id: socket.assigns.data_source.id,
        sql_template: socket.assigns.sql_template,
        datetime: DateTime.utc_now(),
        timezone: socket.assigns.timezone,
        period: 28,
        window_size: window_size,
        comparing_period: 7
      })
      |> case do
        {:ok, raw_data} ->
          preview = QueryData.format_data_for_preview(raw_data)
          parsed_data = QueryData.refine_data_based_on_columns(raw_data, raw_data.columns)
          columns = parsed_data |> Map.keys()

          socket
          |> assign(:data_loaded, true)
          |> assign(:query_error_message, nil)
          |> assign(:preview, preview)
          |> assign(:query_result_by_columns, parsed_data)
          |> assign(:columns, columns)
          |> assign(:selected_columns, columns)
          |> add_draw_chart_events(parsed_data, columns)
          |> assign(
            :report_changeset,
            ReportParams.changeset(
              ReportParams.init_attrs(%{
                "org_id" => socket.assigns.org_id,
                "integration_info" => %{
                  "integration_id" => socket.assigns.integration.id
                },
                "data_source_info" => %{
                  "data_source_id" => socket.assigns.data_source.id,
                  "sql_template" => socket.assigns.sql_template,
                  "timezone" => socket.assigns.timezone,
                  "period" => 28,
                  "window_size" => window_size,
                  "comparing_period" => 7,
                  "columns" => columns
                }
              })
            )
          )

        {:error, error} ->
          socket |> assign(:query_error_message, inspect(error))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_report", %{"report" => report_inputs}, socket) do
    report_changeset = validate_report_changeset(socket, report_inputs)

    socket = socket |> assign(:report_changeset, report_changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_report", %{"report" => report_inputs}, socket) do
    report_params =
      validate_report_changeset(socket, report_inputs)
      |> Params.to_map()

    socket = socket |> create_report(report_params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_preview", params, socket) do
    %{"send_preview_form" => %{"channel" => channel_id}} = params

    Task.start(fn ->
      save_chart_img_params =
        [
          {:data, socket.assigns.query_result_by_columns},
          {:orgId, socket.assigns.org_id},
          {:reportId, "preview"}
        ]
        |> Enum.into(%{})

      {:ok, %{"body" => %{"imgUrls" => img_urls}}, _full_resp} =
        save_chart_image(save_chart_img_params)

      with {:ok, _} <-
             Slack.build_post_message_args(socket.assigns.query_result_by_columns, img_urls)
             |> Enum.map(fn slack_arg ->
               Noti.send_report_to_slack(
                 channel_id,
                 slack_arg,
                 socket.assigns.integration.conn_info.info["bot_token"]
               )
             end)
             |> Traversable.traverse() do
        :ok
      else
        {:error, error} ->
          Logger.error(inspect(error))

          {:error, error}
      end
    end)

    socket =
      socket
      |> put_flash_for(:info, "선택한 쿼리 결과에 대한 슬랙 메시지가 발송되었습니다! 😊", timeout: :timer.seconds(3))
      |> push_event("js-exec", %{to: "#send-preview", attr: "data-hide-modal"})

    {:noreply, socket}
  end

  def handle_event("toggle_show_full_preview_data", _params, socket) do
    socket =
      socket
      |> assign(:show_full_preview_data, !socket.assigns.show_full_preview_data)

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_slack_channel_list", _params, socket) do
    if socket.assigns.is_loading_slack_channels do
      {:noreply, socket}
    else
      socket =
        socket
        |> assign(:is_loading_slack_channels, true)
        |> load_slack_channels()
        |> assign(:is_loading_slack_channels, false)

      # TODO: 선택된 채널 초기화

      {:noreply, socket}
    end
  end

  def render_query_preview(assigns) do
    ~H"""
    <%= if @preview do %>
      <header class="flex justify-between mt-6">
        <h2 class="card-title">쿼리 결과 데이터</h2>
      </header>
      <table class="table mt-4">
        <thead>
          <tr class="w-full">
            <%= for header <- @preview.columns do %>
              <th class="text-center py-3 normal-case"><%= header %></th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for row <- preview_data(@preview.data, @show_full_preview_data) do %>
            <tr class="w-full">
              <%= for value <- row do %>
                <td class="text-center py-2 text-sm bg-base-300"><%= value %></td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
      <button
        class="btn btn-outline btn-sm mt-2"
        type="button"
        phx-click="toggle_show_full_preview_data"
      >
        <%= if @show_full_preview_data do %>
          숨기기
        <% else %>
          더보기
        <% end %>
      </button>
    <% end %>
    """
  end

  defp load_columns(socket, table_name) do
    QueryData.fetch_columns(%{
      org_id: socket.assigns.org_id,
      data_source_id: socket.assigns.data_source.id,
      table_name: table_name
    })
    |> case do
      {:ok, %{date_columns: date_columns, value_columns: value_columns}} ->
        socket
        |> assign(:date_columns, date_columns)
        |> assign(:value_columns, value_columns)

      {:error, _} ->
        socket
    end
  end

  defp create_report(socket, params) do
    case Reports.create_report(params) do
      {:ok, %Report{name: report_name}} ->
        socket
        |> put_flash_for(:info, "\"#{report_name}\" 레포트가 저장되었습니다.", timeout: :timer.seconds(3))
        |> push_navigate(to: Routes.report_index_path(socket, :index))

      {:error, error} ->
        Logger.error(inspect(error))

        socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
    end
  rescue
    e ->
      Logger.error(inspect(e))

      socket |> put_flash_for(:error, "레포트 생성에 실패하였습니다.", timeout: :timer.seconds(3))
  end

  defp add_draw_chart_events(socket, parsed_data, selected_columns) do
    parsed_data
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} -> Enum.member?(selected_columns, k) end)
    |> Enum.reduce(socket, fn {k, v}, acc ->
      push_event(acc, "input_data_#{k}", v)
    end)
  end

  defp save_chart_image(%{orgId: orgId, reportId: reportId, data: data}) do
    %{orgId: orgId, reportId: reportId, data: data}
    |> Aws.save_chart_img()
  end

  defp value_color(value) when is_number(value) do
    case value do
      value when value > 0 -> "text-green-500"
      value when value < 0 -> "text-red-500"
      _ -> ""
    end
  end

  defp value_color(_), do: ""

  defp wow_text(wow) when is_number(wow), do: "#{wow}%"
  defp wow_text(_), do: "-"

  defp load_slack_channels(socket) do
    case Slack.list_conversations(socket.assigns.integration.conn_info.info["bot_token"]) do
      {:ok, channels} ->
        channel_options = channels |> Enum.map(fn %{id: id, name: name} -> {name, id} end)

        socket
        |> assign(:channels, channel_options)
        |> put_flash_for(:info, "슬랙 채널 업데이트 완료", timeout: :timer.seconds(3))

      {:error, _reason} ->
        socket
        |> put_flash_for(:error, "슬랙 채널 업데이트에 실패하였습니다. 다시 시도해주세요.", timeout: :timer.seconds(3))
    end
  end

  defp preview_data(preview, show_all) do
    case show_all do
      true -> preview
      false -> preview |> Enum.take(5)
    end
  end

  defp validate_report_changeset(
         socket,
         %{"hour" => hour_str, "integration_info" => %{"channel_id" => channel_id}} =
           report_inputs
       ) do
    trigger_time =
      TimeHelper.from!(hour: hour_str |> String.to_integer())
      |> TimeHelper.to_utc_time(socket.assigns.timezone)

    channel_name =
      socket.assigns.channels
      |> Enum.find_value(fn
        {channel_name, ^channel_id} -> channel_name
        _ -> nil
      end)

    attrs =
      report_inputs
      |> MapHelper.deep_merge(%{
        "trigger_time" => trigger_time,
        "integration_info" => %{
          "channel_name" => channel_name
        }
      })

    _changeset =
      ReportParams.changeset(attrs)
      |> Params.set_action(:validate)
  end

  defp is_valid_sql_template(query_validations) do
    query_validations |> Map.values() |> Enum.all?()
  end

  defp convert_window_size("일반"), do: 1
  defp convert_window_size("이동합계"), do: 7
end
