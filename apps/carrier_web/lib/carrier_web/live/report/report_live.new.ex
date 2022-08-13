defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData

  @sample_sql_template """
  SELECT DATE(order_date) as date, SUM(amount) AS total_amount
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
      |> assign_new(:query_result, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def handle_event("run_query", params, socket) do
    %{"query" => %{"sql_template" => sql_template}} = params

    socket = socket |> assign(:sql_template, sql_template)

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
        {:ok, %{columns: columns, data: data}} ->
          socket
          |> assign(:query_result, parse_data(%{columns: columns, data: data}))
          |> push_event("input_data", %{columns: columns, data: data})

        {:error, error} ->
          socket |> put_flash(:error, error)
      end

    {:noreply, socket}
  end

  defp parse_data(%{columns: columns, data: data}) do
    raw_key = List.last(columns)
    sum_key = raw_key <> "_window_sum"
    percentage_diff_key = raw_key <> "_window_sum_over"
    current_datum = List.last(data)
    previous_datum = Enum.at(data, -8)

    with {:ok, current_raw} <- Access.fetch(current_datum, raw_key),
         {:ok, previous_raw} <- Access.fetch(previous_datum, raw_key),
         {:ok, current_period_raw} <- Access.fetch(current_datum, sum_key),
         {:ok, percentage_diff} <- Access.fetch(current_datum, percentage_diff_key) do
      raw_wow = ((current_raw / previous_raw - 1) * 100) |> Float.round(2) |> to_string()
      period_wow = ((percentage_diff - 1) * 100) |> Float.round(2) |> to_string()

      %{
        label: raw_key,
        current_raw: current_raw,
        current_period_raw: current_period_raw,
        raw_wow: raw_wow,
        period_wow: period_wow
      }
    else
      err -> {:err, err}
    end
  end
end
