defmodule CarrierWeb.HomeLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(:report_count, 1428)

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

  defp format_report_count(report_count) do
    report_count
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
