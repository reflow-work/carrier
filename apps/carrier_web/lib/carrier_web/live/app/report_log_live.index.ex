defmodule CarrierWeb.App.ReportLogLive.Index do
  use CarrierWeb, :live_view
  use Carrier.Reports
  import CarrierWeb.ChanneltalkHelper
  alias CarrierWeb.Components.InfiniteScroll
  alias Carrier.Core.{Crypto, Nillable}

  @impl true
  def mount(params, _session, socket) do
    report_id = params["report_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Report))

    socket =
      socket
      |> stream(:report_logs, [])
      |> assign(report_id: report_id)

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
        <div class="overflow-x-auto overflow-y-hidden">
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
          <.live_component
            module={InfiniteScroll}
            id="infinite_scroll"
            loader={fn page_params -> load_report_logs(@report_id, page_params) end}
            size={50}
          />
        </div>
      </section>
    </.page_container>
    """
  end

  @impl true
  def handle_info({:loaded_more, report_logs}, socket) do
    socket =
      socket
      |> stream(:report_logs, report_logs)

    {:noreply, socket}
  end

  defp load_report_logs(report_id, page_params) do
    case report_id do
      nil -> Reports.list_report_logs(page_params)
      report_id -> Reports.list_report_logs_by_report_id(report_id, page_params)
    end
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
