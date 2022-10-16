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
    <section class="page-container" id="reports-index-container" phx-hook="Smartlook">
      <header class="page-header">
        <h1 class="page-title">
          <span class="page-title-icon">💾</span> 레포트 발송 기록
        </h1>
      </header>

      <section class="mt-6">
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr>
                <th>ID</th>
                <th>레포트 이름</th>
                <th>상태</th>
                <th>발송 예약 시간</th>
                <th>발송 성공 시간</th>
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
      </section>
    </section>
    """
  end

  defp load_report_logs() do
    {:ok, report_logs} = Carrier.Reports.list_report_logs()

    report_logs
  end
end
