defmodule CarrierWeb.HomeLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> load_report_count()

    {:ok, socket, layout: {CarrierWeb.LayoutView, "landing.html"}}
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

  defp load_report_count(socket) do
    socket |> assign(:report_count, 1428)
  end
end
