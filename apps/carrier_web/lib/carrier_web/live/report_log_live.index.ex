defmodule CarrierWeb.ReportLogLive.Index do
  use CarrierWeb, :live_view

  alias Carrier.Core.Crypto

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
                  <td><%= report_log.id |> Crypto.obfuscate() %></td>
                  <td><%= report_log.report.name %></td>
                  <td>
                    <span class={"badge #{report_log.status}"}>
                      <%= report_log.status |> format_status %>
                    </span>
                  </td>
                  <td>
                    <%= report_log.scheduled_at |> format_datetime(@timezone) %>
                  </td>
                  <td>
                    <%= report_log.succeeded_at |> format_datetime(@timezone) %>
                  </td>
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

  defp format_status(status) do
    case status do
      :scheduled ->
        "발송 예약"

      :tried ->
        "발송중"

      :succeeded ->
        "발송 성공"

      :failed ->
        "발송 실패"

      :cancelled ->
        "발송 취소"
    end
  end

  defp format_datetime(datetime, timezone) when not is_nil(datetime) and not is_nil(timezone) do
    datetime
    |> DateTime.shift_zone!(timezone)
    |> Timex.format!("{YYYY}년 {M}월 {D}일 {h24}시 {m}분")
  end

  defp format_datetime(_datetime, _timezone), do: nil
end
