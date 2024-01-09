defmodule CarrierWeb.Admin.ReportLogLive.Index do
  use CarrierWeb, :live_view
  use Carrier.Reports

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> load_error_report_logs()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.table id="error_report_logs" rows={@error_report_logs}>
      <:col :let={error_report_log} label="id"><%= error_report_log.id %></:col>
      <:col :let={error_report_log} label="org_id"><%= error_report_log.org_id %></:col>
      <:col :let={error_report_log} label="report_id"><%= error_report_log.report_id %></:col>
      <:col :let={error_report_log} label="report_job_id"><%= error_report_log.report_job_id %></:col>
      <:col :let={error_report_log} label="status"><%= error_report_log.status %></:col>
      <:col :let={error_report_log} label="error_message"><%= error_report_log.error_message %></:col>
      <:col :let={error_report_log} label="actions">
        <.button phx-click={JS.push("retry", value: %{report_log_id: error_report_log.id})}>
          Retry
        </.button>
      </:col>
    </.table>
    """
  end

  @impl true
  def handle_event("retry", %{"report_log_id" => report_log_id}, socket) do
    report_log_id |> IO.inspect()

    {:noreply, socket}
  end

  defp load_error_report_logs(socket) do
    {:ok, error_report_logs} = Reports.Super.list_error_report_logs()

    socket
    |> assign(:error_report_logs, error_report_logs)
  end
end
