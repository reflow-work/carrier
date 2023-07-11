defmodule CarrierWeb.App.ReportLogLive.Index do
  use CarrierWeb, :live_view
  use Carrier.Reports
  import CarrierWeb.ChanneltalkHelper
  alias Carrier.Core.{Crypto, Nillable}

  @init_page_params %{next_cursor: nil, size: 5, last?: false}

  @impl true
  def mount(params, _session, socket) do
    report_id = params["report_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Report))

    socket =
      socket
      |> assign(page_params: @init_page_params)
      |> assign(report_id: report_id)
      |> load_report_logs()

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
          <.table id="report_logs" rows={@streams.report_logs}>
            <:col :let={report_log} label="ID">
              <%= Crypto.obfuscate(report_log.report_info_id) %>
            </:col>
            <:col :let={report_log} label="리포트 이름"><%= report_log.report.name %></:col>
            <:col :let={report_log} label="상태">
              <span class={badge_class(report_log)}><%= transl_status(report_log) %></span>
            </:col>
            <:col :let={report_log} label="발송 예약 시각">
              <%= report_log.scheduled_at |> format_datetime() %>
            </:col>
            <:col :let={report_log} label="발송 성공 시각">
              <%= report_log.succeeded_at |> format_datetime() %>
            </:col>
          </.table>
        </div>
      </section>
    </.page_container>
    """
  end

  defp load_report_logs(socket) do
    {report_logs, page_params} =
      case socket.assigns.report_id do
        nil ->
          {:ok, %{entries: report_logs, meta: meta}} =
            Carrier.Reports.list_report_logs(socket.assigns.page_params)

          {report_logs, meta}

        report_id ->
          {:ok, report_logs} = Carrier.Reports.list_report_logs_by_report_id(report_id)

          {report_logs, nil}
      end

    socket
    |> stream(:report_logs, report_logs)
    |> assign(:page_params, page_params)
  end

  defp badge_class(%ReportLog{status: status}) do
    ["p-2 border-0 rounded text-sm"]
    |> Kernel.++(
      case status do
        :scheduled -> ["bg-blue-300"]
        :succeeded -> ["bg-green-200"]
        :tried -> ["bg-amber-300"]
        :failed -> ["bg-red-300"]
        _ -> []
      end
    )
  end

  defp transl_status(%ReportLog{status: status}) do
    case status do
      :scheduled -> "발송 예약"
      :tried -> "발송중"
      :succeeded -> "발송 성공"
      :failed -> "발송 실패"
      :cancelled -> "발송 취소"
    end
  end
end
