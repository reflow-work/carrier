defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view
  use Carrier.Secrets
  alias Carrier.Core.Nillable

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  embed_templates "new2/*"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:title, nil)
      |> assign(:selected_data_source, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{live_action: :new}} = socket) do
    socket =
      socket
      |> assign(:title, "레포트 생성하기")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <header class="page-header">
        <h1 class="page-title">
          <span class="page-title-icon">📊</span> <%= @title %>
        </h1>
      </header>
      <.data_source_selector
        data_sources={@data_sources}
        selected_data_source={@selected_data_source}
        onselect="select_data_source"
      />
    </section>
    """
  end

  @impl true
  def handle_event("select_data_source", %{"id" => data_source_id_str}, socket) do
    data_source_id = data_source_id_str |> String.to_integer()

    socket =
      socket
      |> assign(
        :selected_data_source,
        socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))
      )

    {:noreply, socket}
  end

  attr :data_sources, :list, required: true
  attr :selected_data_source, :any, required: true
  attr :onselect, :any, required: true

  def data_source_selector(assigns)

  defp data_source_options(data_sources) do
    data_sources
    |> Enum.map(fn %DataSource{id: id, name: name} -> {name, id} end)
  end
end
