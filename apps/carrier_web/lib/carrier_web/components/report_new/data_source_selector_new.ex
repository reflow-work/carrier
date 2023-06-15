defmodule CarrierWeb.Components.DataSourceSelectorNew do
  use CarrierWeb, :live_component
  use Carrier.{Integrations}
  alias Carrier.Integrations.DataSource
  alias Carrier.Core.{Nillable}

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:data_sources, [])
      |> assign(:selected_data_source_id, nil)
      |> load_data_sources()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    if selected_data_source_id = socket.assigns.selected_data_source_id do
      selected_data_source =
        socket.assigns.data_sources |> Enum.find(&(&1.id == selected_data_source_id))

      send(self(), {:data_source_selected, selected_data_source})
    end

    {:ok, socket}
  end

  defp load_data_sources(socket) do
    case Integrations.list_data_sources() do
      [_ | _] = data_sources ->
        socket |> assign(:data_sources, data_sources)

      _ ->
        socket
        |> put_flash_for(:error, "데이터 소스를 불러오는데 실패하였습니다.", timeout: :timer.seconds(3))
    end
  end

  defp data_source_options(data_sources) do
    data_sources
    |> Enum.map(fn %DataSource{id: id, name: name} -> {name, id} end)
  end

  @impl true
  def handle_event("select_data_source", %{"id" => data_source_id_str}, socket) do
    data_source_id = data_source_id_str |> String.to_integer()
    selected_data_source = socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))

    send(self(), {:data_source_selected, selected_data_source})

    {:noreply, socket}
  end
end
