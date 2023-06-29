defmodule CarrierWeb.HomeLive do
  use CarrierWeb, :live_view
  use Carrier.Reports
  alias Carrier.Const

  import CarrierWeb.Components.Landing.Section, only: [feature: 1]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:report_log_count, nil)
      |> load_report_log_count()

    {:ok, socket}
  end

  defp load_report_log_count(socket) do
    {:ok, count} = Reports.Super.get_report_log_count()

    socket |> assign(:report_log_count, count)
  end
end
