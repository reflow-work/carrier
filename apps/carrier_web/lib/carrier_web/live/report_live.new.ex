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
      |> assign_new(:sample, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>
        <.form let={f} for={:report} id="report_form" phx-hook="ReportForm">
          <%= textarea(f, :sql_template, class: "textarea textarea-bordered", placeholder: "SQL here", value: @sql_template) %>

          <%= submit "sample", type: "button", name: "sample" %>
          <%= submit "analyze", type: "button", name: "analyze" %>
        </.form>
      </div>
      <div>
        <%= if @sample do %>
          <table>
            <thead>
              <tr>
                <%= for column <- @sample.columns do %>
                  <th><%= column %></th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for datum <- @sample.data do %>
                <tr>
                  <%= for column <- @sample.columns do %>
                    <td><%= datum[column] %></td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("sample", params, socket) do
    %{"report" => %{"sql_template" => sql_template}} = params |> parse_form_data()

    socket = socket |> assign(:sql_template, sql_template)

    socket =
      QueryData.query_sample(%{
        org_id: 1,
        conn_info_id: 1,
        sql_template: sql_template,
        datetime: DateTime.utc_now(),
        timezone: "Asia/Seoul",
        period: 28,
        limit: 5
      })
      |> case do
        {:ok, %{columns: columns, data: data}} ->
          socket |> assign(:sample, %{columns: columns, data: data})

        {:error, error} ->
          socket |> put_flash(:error, error)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("analyze", params, socket) do
    params |> parse_form_data() |> IO.inspect()

    {:noreply, socket}
  end

  defp parse_form_data(form_data) do
    form_data
    |> Enum.reduce(%{}, fn {key, value}, map ->
      [key0, key1] = parse_form_data_key(key)

      map |> put_in([Access.key(key0, %{}), key1], value)
    end)
  end

  defp parse_form_data_key(key) do
    key |> String.split(["[", "]"], trim: true)
  end
end
