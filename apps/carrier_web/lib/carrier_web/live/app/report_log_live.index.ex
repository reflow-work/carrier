defmodule CarrierWeb.App.ReportLogLive.Index do
  use CarrierWeb, :live_view
  use Carrier.Reports
  import CarrierWeb.ChanneltalkHelper
  alias Carrier.Core.{Crypto, Nillable}

  @impl true
  def mount(params, _session, socket) do
    report_id = params["report_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Report))

    socket =
      socket
      |> load_report_logs(report_id)

    socket =
      case params["open_message"] do
        nil -> socket
        _ -> socket |> open_channel_talk()
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container id="reports-index-container" phx-hook="Smartlook">
      <.page_header icon="💾" title="리포트 발송 기록" />

      <section class="mt-6">
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr>
                <th>ID</th>
                <th>리포트 이름</th>
                <th>상태</th>
                <th>발송 예약 시간</th>
                <th>발송 성공 시간</th>
              </tr>
            </thead>
            <tbody>
              <%= for report_log <- @report_logs do %>
                <tr>
                  <td><%= report_log.report_info_id |> Crypto.obfuscate() %></td>
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
    </.page_container>
    """
  end

  defp load_report_logs(socket, nil) do
    {:ok, report_logs} = Carrier.Reports.list_report_logs()

    socket
    |> assign(:report_logs, report_logs)
  end

  defp load_report_logs(socket, report_id) do
    {:ok, report_logs} = Carrier.Reports.list_report_logs_by_report_id(report_id)

    socket
    |> assign(:report_logs, report_logs)
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
