defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view
  use Carrier.Integrations
  alias __MODULE__.Components
  alias Carrier.Core.Nillable

  on_mount(CarrierWeb.DataTargetHook)
  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:title, nil)
      |> assign(:selected_data_source, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :new}} = socket) do
    data_source_id = params["data_source_id"] |> Nillable.map(&Obfuscatable.deobfuscate!/1)

    socket =
      socket
      |> assign(:title, "레포트 생성하기")
      |> Nillable.run(data_source_id, fn socket ->
        socket
        |> assign(
          :selected_data_source,
          socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))
        )
      end)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="📊" title={@title} />
      <Components.data_source_selector
        data_sources={@data_sources}
        selected_data_source={@selected_data_source}
        onselect="select_data_source"
      />
      <Components.data_transformer data_source={@selected_data_source} />
      <Components.data_target_configurer data_target={@data_target} />
      <Components.report_configurer />
    </section>
    """
  end

  ### Data Source Selector ###

  @impl true
  def handle_event("select_data_source", %{"id" => data_source_id_str}, socket) do
    data_source_id = data_source_id_str |> String.to_integer()

    socket =
      socket
      |> assign(
        :selected_data_source,
        socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))
      )
      |> init_data_source_info()

    {:noreply, socket}
  end

  defp init_data_source_info(socket) do
    # %DataSource{id: data_source_id, source: source} = socket.assigns.selected_data_source

    socket
    # |> assign(:data_source_info, %{data_source_id: data_source_id, source: source})
  end

  @impl true
  def handle_info(message, socket) do
    case handle_async_assigns(message, socket) do
      {:ok, socket} ->
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end
end
