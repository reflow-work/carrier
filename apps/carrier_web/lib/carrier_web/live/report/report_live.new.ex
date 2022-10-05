defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData
  alias Carrier.Reports
  alias Carrier.Reports.Report
  alias Carrier.Noti
  alias Carrier.External.Slack
  alias Carrier.External.Aws
  alias Carrier.Core.{TimeHelper, Traversable}
  alias CarrierWeb.Components.Empty
  import CarrierWeb.LiveHelpers

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @sample_sql_template """
  SELECT DATE(order_date) as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
    FROM sample_data_simple
    WHERE DATE(order_date) >= {{start}} AND DATE(order_date) < {{end}}
    GROUP BY order_date
    ORDER BY order_date
  """

  @impl true
  def mount(_params, _session, socket) do
    {:ok, channels} =
      Slack.list_conversations(socket.assigns.integration.conn_info.info["bot_token"])

    channel_options = channels |> Enum.map(fn %{id: id, name: name} -> {name, id} end)

    socket =
      socket
      |> assign_new(:sql_template, fn -> @sample_sql_template end)
      |> assign_new(:query_result_raw, fn -> nil end)
      |> assign_new(:query_result_by_columns, fn -> nil end)
      |> assign_new(:query_result_for_preview, fn -> nil end)
      |> assign_new(:show_full_preview_data, fn -> false end)
      |> assign_new(:show_preview_modal, fn -> false end)
      |> assign_new(:selected_columns, fn -> [] end)
      |> assign_new(:report_id, fn -> nil end)
      |> assign_new(:channels, fn -> channel_options end)
      |> assign_new(:hours, fn -> 0..23 |> Enum.map(&{"매일 #{&1}시", &1}) end)
      |> assign_new(:window_sizes, fn -> [1, 7] end)
      |> assign_new(:is_report_valid, fn -> false end)
      |> assign(:timezone, "Asia/Seoul")
      |> assign(:period, 28)
      |> assign(:window_size, 7)
      |> assign(:comparing_period, 7)

    {:ok, socket}
  end

  @impl true
  def handle_event("run_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket =
      socket
      |> assign(:sql_template, sql_template)

    {:ok, datetime} = DateTime.now("Asia/Seoul")

    socket =
      QueryData.query(%{
        org_id: socket.assigns.org_id,
        data_source_id: socket.assigns.data_source.id,
        sql_template: sql_template,
        datetime: datetime,
        timezone: socket.assigns.timezone,
        period: socket.assigns.period,
        window_size: socket.assigns.window_size,
        comparing_period: socket.assigns.comparing_period
      })
      |> case do
        {:ok, raw_data} ->
          parsed_data = QueryData.refine_data_based_on_columns(raw_data, raw_data.columns)

          formatted_data = QueryData.format_data_for_preview(raw_data)

          selected_columns =
            parsed_data
            |> Map.keys()

          socket
          |> assign(:query_result_raw, raw_data)
          |> assign(:query_result_by_columns, parsed_data)
          |> assign(:query_result_for_preview, formatted_data)
          |> assign(:selected_columns, selected_columns)
          |> add_draw_chart_events(parsed_data, selected_columns)

        {:error, error} ->
          socket |> put_flash_for(:error, inspect(error), timeout: :timer.seconds(3))
      end

    {:noreply, socket}
  end

  def handle_event("select_window_size", params, socket) do
    %{"data_window_size" => %{"window_size" => window_size}} = params

    socket =
      socket
      |> assign(:window_size, Integer.parse(window_size))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_data_column", params, socket) do
    %{"data_columns" => data_columns} = params

    selected_columns =
      data_columns
      |> Map.to_list()
      |> Enum.filter(fn {_k, v} -> v == "true" end)
      |> Enum.map(fn {k, _v} -> k end)

    socket =
      socket
      |> assign(:selected_columns, selected_columns)
      |> add_draw_chart_events(socket.assigns.query_result_by_columns, selected_columns)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_report", %{"report" => report_input}, socket) do
    %{"name" => name, "channel" => channel_id, "hour" => hour_str} = report_input

    trigger_time =
      TimeHelper.from!(hour: hour_str |> String.to_integer())
      |> TimeHelper.to_utc_time(socket.assigns.timezone)

    {channel_name, _} =
      socket.assigns.channels |> Enum.find(fn {_name, id} -> id == channel_id end)

    socket =
      socket
      |> create_report(%{
        org_id: socket.assigns.org_id,
        name: name,
        trigger_time: trigger_time,
        integration_info: %{
          integration_id: socket.assigns.integration.id,
          channel_id: channel_id,
          channel_name: channel_name
        },
        data_source_info: %{
          data_source_id: socket.assigns.data_source.id,
          sql_template: socket.assigns.sql_template,
          timezone: socket.assigns.timezone,
          period: socket.assigns.period,
          window_size: socket.assigns.window_size,
          comparing_period: socket.assigns.comparing_period,
          columns: socket.assigns.selected_columns
        }
      })

    {:noreply, socket}
  end

  def handle_event("validate", %{"report" => report_input}, socket) do
    %{"name" => name, "channel" => channel_id, "hour" => hour_str} = report_input

    socket =
      if name && name != "" && channel_id && hour_str do
        socket
        |> assign(:is_report_valid, true)
      else
        socket
        |> assign(:is_report_valid, false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_preview", params, socket) do
    %{"send_preview_form" => %{"channel" => channel_id}} = params

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
      socket =
        socket
        |> put_flash_for(:info, "Slack messages for the selected query results have been sent! 😊",
          timeout: :timer.seconds(3)
        )
        |> assign(:show_preview_modal, false)

      {:noreply, socket}
    else
      {:error, error} ->
        Logger.error(error)

        socket =
          socket
          |> put_flash_for(
            :error,
            "Failed to send one or more slack messages for selected query results! 😮",
            timeout: :timer.seconds(3)
          )

        {:noreply, socket}
    end
  end

  def handle_event("show_preview_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_preview_modal, true)

    {:noreply, socket}
  end

  def handle_event("toggle_show_full_preview_data", _params, socket) do
    socket =
      socket
      |> assign(:show_full_preview_data, !socket.assigns.show_full_preview_data)

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:show_preview_modal, false)

    {:noreply, socket}
  end

  defp create_report(socket, params) do
    case Reports.create_report(params) do
      {:ok, %Report{name: report_name}} ->
        socket
        |> put_flash_for(:info, "Report \"#{report_name}\" has been saved!",
          timeout: :timer.seconds(3)
        )
        |> push_redirect(to: Routes.report_index_path(socket, :index))

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
end
