defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData
  alias Carrier.Reports
  alias Carrier.Noti
  alias Carrier.External.Aws

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
    socket =
      socket
      |> assign_new(:sql_template, fn -> @sample_sql_template end)
      |> assign_new(:query_result_parsed, fn -> %{} end)
      |> assign_new(:query_result_raw, fn -> %{} end)
      |> assign_new(:selected_columns, fn -> [] end)
      |> assign_new(:report_id, fn -> nil end)
      |> assign_new(:channels, fn -> ["a", "b", "c"] end)
      |> assign_new(:hours, fn -> 0..23 end)

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
        timezone: "Asia/Seoul",
        period: 28,
        window_size: 7,
        comparing_period: 7
      })
      |> case do
        {:ok, raw_data} ->
          parsed_data = parse_data(raw_data)

          selected_columns =
            parsed_data
            |> Map.keys()

          socket
          |> assign(:query_result_parsed, parsed_data)
          |> assign(:query_result_raw, raw_data)
          |> assign(:selected_columns, selected_columns)
          |> add_draw_chart_events(parsed_data, selected_columns)

        {:error, error} ->
          socket |> put_flash(:error, error)
      end

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
      |> add_draw_chart_events(socket.assigns.query_result_parsed, selected_columns)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_report", params, socket) do
    %{"report" => %{"name" => name, "channel" => _channel, "hour" => _hour}} = params

    socket =
      socket
      |> create_report(%{name: name})

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_preview", _params, socket) do
    save_chart_img_params =
      [
        {:data, socket.assigns.query_result_parsed},
        {:orgId, socket.assigns.org_id},
        {:reportId, "preview"}
      ]
      |> Enum.into(%{})

    {:ok, %{"body" => %{"imgUrls" => img_urls}}, _full_resp} =
      save_chart_image(save_chart_img_params)

    slack_post_message_aggregated_result =
      build_slack_args(socket.assigns.query_result_parsed, img_urls)
      |> Enum.map(fn slack_arg ->
        Noti.send_report_to_slack(
          "C03U2QWU7F1",
          slack_arg,
          "xoxb-3700242262145-3896134834753-QZ1WpkILGCgWy7bctc47CoLz"
        )
      end)
      |> Enum.all?(fn result -> result == :ok end)

    if slack_post_message_aggregated_result == true do
      socket =
        socket
        |> put_flash(:info, "Slack messages for the selected query results have been sent! 😊")

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(
          :error,
          "Failed to send one or more slack messages for selected query results! 😮"
        )

      {:noreply, socket}
    end
  end

  defp build_slack_args(data, img_urls) do
    data
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      %{
        title: v.meta.label,
        raw: %{
          yesterday: v.meta.current_period_last_tick_raw,
          last_week: v.meta.previous_period_last_tick_raw
        },
        weekly_sum: %{
          last_week: v.meta.current_period_sum,
          week_over_week: v.meta.diff_between_periods_in_percentage
        },
        img_url: Map.get(img_urls, k)
      }
    end)
  end

  defp create_report(socket, params) do
    params = params |> Map.put(:org_id, socket.assigns.org_id)

    case Reports.create_reports(params) do
      {:ok, report} ->
        socket
        |> put_flash(:info, "Report \"#{report.name}\" has been saved!")
        |> assign("report_id", report.id)

      {:error, error} ->
        socket |> put_flash(:error, error)
    end
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

  defp build_meta_data(key, data) do
    current_period_sum_key = key <> "_window_sum"
    previous_period_sum_key = key <> "_window_sum_offset"
    current_to_previous_periods_sum_ratio_key = key <> "_window_sum_over"

    last_datum =
      data
      |> List.last(data)

    previous_period_last_datum = Enum.at(data, -8)

    diff_between_periods_in_percentage =
      last_datum[current_to_previous_periods_sum_ratio_key]
      |> Decimal.from_float()
      |> Decimal.sub(1)
      |> Decimal.round(4)
      |> Decimal.mult(100)
      |> Decimal.to_float()

    %{
      label: key,
      current_period_last_tick_raw: last_datum[key],
      previous_period_last_tick_raw: previous_period_last_datum[key],
      current_period_sum: last_datum[current_period_sum_key],
      previous_period_sum: last_datum[previous_period_sum_key],
      current_to_previous_periods_sum_ratio:
        last_datum[current_to_previous_periods_sum_ratio_key],
      diff_between_periods_in_percentage: diff_between_periods_in_percentage
    }
  end

  defp parse_data(%{columns: columns, data: data}) do
    non_date_keys =
      columns
      |> Enum.filter(&(&1 !== "date"))

    non_date_keys
    |> Enum.map(fn key ->
      data_by_column = split_data_by_columns(key, data)
      meta_data = build_meta_data(key, data_by_column)

      {key, Enum.into([{:meta, meta_data}, {:data, data_by_column}], %{})}
    end)
    |> Enum.into(%{})
  end

  defp split_data_by_columns(key, data) do
    current_period_sum_key = key <> "_window_sum"
    previous_period_sum_key = key <> "_window_sum_offset"
    current_to_previous_periods_sum_ratio = key <> "_window_sum_over"

    Enum.map(
      data,
      fn datum ->
        %{
          :date => datum["date"],
          key => datum[key],
          current_period_sum_key => datum[current_period_sum_key],
          previous_period_sum_key => datum[previous_period_sum_key],
          current_to_previous_periods_sum_ratio => datum[current_to_previous_periods_sum_ratio]
        }
      end
    )
  end
end
