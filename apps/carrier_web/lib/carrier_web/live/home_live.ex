defmodule CarrierWeb.HomeLive do
  use CarrierWeb, :live_view
  use Carrier.Reports
  alias Carrier.Core.DateHelper

  import CarrierWeb.Components.Landing.Section, only: [feature: 1]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:report_log_count, nil)
      |> load_report_log_count()

    {:ok, socket}
  end

  @impl true
  def handle_event("click_link", %{"name" => name, "to" => to}, socket) do
    socket =
      socket
      |> log_event(name, %{
        page_name: "landing"
      })

    {:noreply, push_navigate(socket, to: to)}
  end

  defp load_report_log_count(socket) do
    {:ok, count} = Reports.Super.get_report_log_count()

    socket |> assign(:report_log_count, count)
  end
end
