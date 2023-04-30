defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view
  use Carrier.Secrets
  alias __MODULE__.Components

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:title, nil)
      |> assign(:selected_data_source, nil)
      |> assign(:data_transformer_onselects, %{})

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
      <.page_header icon="📊" title={@title} />
      <Components.data_source_selector
        data_sources={@data_sources}
        selected_data_source={@selected_data_source}
        onselect="select_data_source"
      />
      <Components.data_transformer
        data_source={@selected_data_source}
        onselects={@data_transformer_onselects}
      />
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
    data_source = socket.assigns.selected_data_source

    socket
    |> do_init_common_data_source_info(data_source)
    |> do_init_data_source_info(data_source)
  end

  defp do_init_common_data_source_info(socket, %DataSource{id: data_source_id, source: source}) do
    socket
    |> assign(:data_source_info, %{data_source_id: data_source_id, source: source})
  end

  defp do_init_data_source_info(socket, %DataSource{source: :tableau}) do
    socket
    |> assign(:data_transformer_onselects, %{select_tableau_view: &{:select_tableau_view, &1}})
  end

  # TODO: implement it
  defp do_init_data_source_info(socket, %DataSource{}) do
    socket
  end

  ### Data Transformer ###

  @impl true
  def handle_info({:select_tableau_view, selected_views}, socket) do
    selected_views |> IO.inspect()

    {:noreply, socket}
  end
end
