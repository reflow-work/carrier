defmodule CarrierWeb.ReportLogLive.Index do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(:report_logs, load_report_logs())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Report</th>
            <th>Status</th>
            <th>Scheduled At</th>
            <th>Succeeded At</th>
          </tr>
        </thead>
        <tbody>
          <%= for report_log <- @report_logs do %>
            <tr>
              <td><%= report_log.id %></td>
              <td><%= report_log.report.name %></td>
              <td><%= report_log.status %></td>
              <td><%= report_log.scheduled_at %></td>
              <td><%= report_log.succeeded_at %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp load_report_logs() do
    {:ok, report_logs} = Carrier.Reports.list_report_logs()

    report_logs
  end
end
