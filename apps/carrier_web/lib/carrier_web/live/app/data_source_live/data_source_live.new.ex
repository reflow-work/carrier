defmodule CarrierWeb.App.DataSourceLive.New do
  use CarrierWeb, :live_view
  use Carrier.Integrations

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:self, self())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={CarrierWeb.Components.DataSourceNew}
      id="data_source_new"
      flash={@flash}
      org={@org}
      onsuccess={fn data_source -> send(@self, {:data_source_created, data_source}) end}
    />
    """
  end

  @impl true
  def handle_info({:data_source_created, %DataSource{source: source} = data_source}, socket) do
    redirect_path =
      case source do
        :tableau -> ~p"/app/reports/new2?data_source_id=#{data_source}"
        _ -> ~p"/app/reports/new?data_source_id=#{data_source}"
      end

    socket =
      socket
      |> push_navigate(to: redirect_path)

    {:noreply, socket}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
