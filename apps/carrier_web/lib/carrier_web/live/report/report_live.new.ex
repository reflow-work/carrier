defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData
  alias Carrier.Reports
  alias Carrier.External.Aws
  alias Carrier.External.Slack

  @sample_sql_template """
  SELECT DATE(order_date) as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
    FROM sample_data_simple
    WHERE DATE(order_date) >= {{start}} AND DATE(order_date) < {{end}}
    GROUP BY order_date
    ORDER BY order_date
  """

  @impl true
  def mount(%{"conn_info_id" => conn_info_id}, _session, socket) do
    socket =
      socket
      |> assign(:conn_info_id, conn_info_id)
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

    # {:ok, datetime} = DateTime.now("Asia/Seoul")
    {:ok, datetime, _n} = DateTime.from_iso8601("2022-07-14T00:00:00Z")

    socket =
      QueryData.query(%{
        org_id: socket.assigns.org_id,
        conn_info_id: socket.assigns.conn_info_id,
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
            |> Enum.map(fn k -> Atom.to_string(k) end)

          socket
          |> assign(:query_result_parsed, parsed_data)
          |> assign(:query_result_raw, raw_data)
          |> assign(:selected_columns, selected_columns)
          |> add_events(parsed_data, selected_columns)

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
      |> add_events(socket.assigns.query_result_parsed, selected_columns)

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
      socket.assigns.query_result_raw
      |> Map.put(:orgId, socket.assigns.org_id)
      |> Map.put(:reportId, "preview")

    {:ok, %{"body" => %{"imgUrl" => img_url}}, _full_resp} =
      save_chart_image(save_chart_img_params)

    args = %{
      title: socket.assigns.query_result_parsed.label,
      yesterday: %{
        raw: socket.assigns.query_result_parsed.current_raw,
        wow: socket.assigns.query_result_parsed.raw_wow
      },
      last_week: %{
        raw: socket.assigns.query_result_parsed.current_period_raw,
        wow: socket.assigns.query_result_parsed.period_wow
      },
      img_url: img_url
    }

    {:ok, %Tesla.Env{body: %{"ok" => result}}} = Slack.post_message("C03U2QWU7F1", args)

    if result == true do
      socket =
        socket
        |> put_flash(:info, "Slack message for the current chart has been sent!")

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Failed to send slack message for the current chart!")

      {:noreply, socket}
    end
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

  defp add_events(socket, parsed_data, selected_columns) do
    parsed_data
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} -> Enum.member?(selected_columns, Atom.to_string(k)) end)
    |> Enum.reduce(socket, fn {k, v}, acc ->
      push_event(acc, "input_data_#{k}", v)
    end)
  end

  defp save_chart_image(%{columns: columns, data: data, orgId: orgId, reportId: reportId}) do
    %{columns: columns, data: data, orgId: orgId, reportId: reportId}
    |> Aws.save_chart_img()
  end

  defp split_data_by_columns(%{columns: columns, data: data}) do
    non_date_keys =
      columns
      |> Enum.filter(&(&1 !== "date"))

    non_date_keys
    |> Enum.map(fn raw_key ->
      data_by_column =
        Enum.reduce(
          data,
          [],
          fn datum, acc ->
            current_period_sum_key = raw_key <> "_window_sum"
            previous_period_sum_key = raw_key <> "_window_sum_offset"
            current_to_previous_periods_sum_ratio = raw_key <> "_window_sum_over"

            item = %{
              :date => datum["date"],
              String.to_existing_atom(raw_key) => datum[raw_key],
              String.to_existing_atom(current_period_sum_key) => datum[current_period_sum_key],
              String.to_existing_atom(previous_period_sum_key) => datum[previous_period_sum_key],
              String.to_existing_atom(current_to_previous_periods_sum_ratio) =>
                datum[current_to_previous_periods_sum_ratio]
            }

            [item | acc]
          end
        )
        |> Enum.sort(&(&1.date <= &2.date))

      meta_data = build_meta_data(raw_key, data_by_column)

      {String.to_existing_atom(raw_key),
       Enum.into([{:meta, meta_data}, {:data, data_by_column}], %{})}
    end)
    |> Enum.into(%{})
  end

  defp build_meta_data(raw_key, data) do
    current_period_sum_key = String.to_existing_atom(raw_key <> "_window_sum")
    previous_period_sum_key = String.to_existing_atom(raw_key <> "_window_sum_offset")

    current_to_previous_periods_sum_ratio_key =
      String.to_existing_atom(raw_key <> "_window_sum_over")

    atom_raw_key = String.to_existing_atom(raw_key)

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
      label: raw_key,
      current_period_last_tick_raw: last_datum[atom_raw_key],
      previous_period_last_tick_raw: previous_period_last_datum[atom_raw_key],
      current_period_sum: last_datum[current_period_sum_key],
      previous_period_sum: last_datum[previous_period_sum_key],
      current_to_previous_periods_sum_ratio:
        last_datum[current_to_previous_periods_sum_ratio_key],
      diff_between_periods_in_percentage: diff_between_periods_in_percentage
    }
  end

  defp parse_data(%{columns: columns, data: data}) do
    split_data_by_columns(%{columns: columns, data: data})
  end
end
