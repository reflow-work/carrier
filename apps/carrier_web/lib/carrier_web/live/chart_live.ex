defmodule CarrierWeb.ChartLive do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, current_date } = Date.from_iso8601("2022-05-11")
    {:ok, socket |> assign(date: current_date)}
  end

  @impl true
  def handle_event("prev", _, socket) do
    current_date = socket.assigns.date
    new_date = Date.add(current_date, -1)
    sql = sql(current_date |> to_string(), current_date |> Date.add(30) |> to_string())
    socket =
      socket
      |> assign(date: new_date)
    {:ok, %{header: header, rows: rows}} = QueryData.query(%{org_id: 1, conn_info_id: 1, sql: sql})
    {:noreply,
     socket
     |> push_event("input_data", %{labels: header, data: rows})}
  end

  @impl true
  def handle_event("next", _, socket) do
    current_date = socket.assigns.date
    new_date = Date.add(current_date, 1)
    sql = sql(current_date |> to_string(), current_date |> Date.add(30) |> to_string())
    socket =
      socket
      |> assign(date: new_date)
    {:ok, %{header: header, rows: rows}} = QueryData.query(%{org_id: 1, conn_info_id: 1, sql: sql})
    {:noreply,
     socket
     |> push_event("input_data", %{labels: header, data: rows})}
  end

  @impl true
  def handle_event("run_query", %{"query_editor" => query}, socket) do
    {:ok, %{header: header, rows: rows}} = QueryData.query(%{org_id: 1, conn_info_id: 1, sql: query})
    {:noreply,
     socket
     |> push_event("input_data", %{labels: header, data: rows})}
  end

  defp sql(date1, date2) do
    """
    SELECT DATE(datetime) as date, SUM(price) AS price_sum
    FROM orders
    WHERE datetime >= '#{date1}'::TIMESTAMP AND datetime < '#{date2}'::TIMESTAMP
    GROUP BY date
    ORDER BY date;
    """
  end
end
