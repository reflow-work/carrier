defmodule CarrierWeb.ReportLive.Index do
  use CarrierWeb, :live_view
  alias Carrier.Reports

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:reports, [])

    socket =
      case connected?(socket) do
        true -> socket |> load_reports()
        false -> socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Report List</h1>

    <div>
      <%= for report <- @reports do %>
        <%= report.name %>
      <% end %>
    </div>
    """
  end

  defp load_reports(socket) do
    case Reports.list_reports() do
      {:ok, reports} ->
        socket |> assign(:reports, reports)

      {:error, reason} ->
        socket
        |> put_flash(:error, inspect(reason))
    end
  end
end
