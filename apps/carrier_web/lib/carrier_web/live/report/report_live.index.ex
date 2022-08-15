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
    <section class="p-8 bg-slate-200 w-full">
      <header>
      <h1 class="text-h1">Report List</h1>
      <%= live_redirect "Create New Report", to: Routes.report_new_path(@socket, :new), class: "border p-2 rounded" %>
      </header>
      <ul class="mt-10 space-y-2 rounded">
        <li class="grid grid-cols-4 border bg-white p-4 items-center rounded">
          <div class="text-h2">Name</div>
          <div class="text-h2">Time</div>
          <div class="text-h2">Channel</div>
          <div class="text-h2">Actions</div>
        </li>
        <%= for report <- @reports do %>
          <li class="grid grid-cols-4 border bg-white p-4 items-center rounded">
            <div><%= report.name %></div>
            <div>15:00</div>
            <div>#roar</div>
            <div>
              <button class="border p-2 rounded">Edit</button>
              <button class="border p-2 rounded">Delete</button>
            </div>
          </li>
          <% end %>
      </ul>
    </section>
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
