defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view
  alias Carrier.Data.QueryData

  @sample_sql_template """
  SELECT DATE(datetime) as date, SUM(sales) AS total_sales
    FROM orders
    WHERE datetime >= {{start}} AND datetime < {{end}}
    GROUP BY date
    ORDER BY date
  """

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:sql_template, fn -> @sample_sql_template end)
      |> assign_new(:analyze, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def handle_event("analyze", params, socket) do
    %{"report" => %{"sql_template" => sql_template}} = params

    socket = socket |> assign(:sql_template, sql_template)

    socket =
      QueryData.query(%{
        org_id: 1,
        conn_info_id: 1,
        sql_template: sql_template,
        datetime: DateTime.utc_now(),
        timezone: "Asia/Seoul",
        period: 28,
        window_size: 7,
        comparing_period: 7
      })
      |> case do
        {:ok, %{columns: columns, data: data}} ->
          socket
          |> assign(:analyze, %{columns: columns, data: data})
          |> push_event("input_data", %{columns: columns, data: data})

        {:error, error} ->
          socket |> put_flash(:error, error)
         end

    {:noreply, socket}
  end

  @impl true
  def handle_event("run_query", %{"query_editor" => query}, socket) do
    socket =
      QueryData.query(
        %{
          org_id: 1,
          conn_info_id: 1,
          sql_template: query,
          datetime: DateTime.utc_now(),
          timezone: "Asia/Seoul",
          period: 28,
          window_size: 7,
          comparing_period: 7
        })
        |> case do
             {:ok, %{columns: columns, data: data}} ->
               socket |> push_event("input_data", %{columns: columns, data: data})
             {:error, error} ->
               socket |> put_flash(:error, error)
           end
    {:noreply, socket}
  end
end
