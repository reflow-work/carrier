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
    <div class="page-container">
      <.page_header icon="⚙️" title="초기 설정하기" />

      <.card_container>
        <.card>
          <div class="flex space-x-6 mb-6">
            <div class="flex items-center">
              <div class="circle gray mr-2">
                1
              </div>
              <div class="text-sm text-description">
                슬랙 연동하기
              </div>
            </div>

            <div class="flex items-center">
              <div class="circle mr-2">
                2
              </div>
              <div class="text-sm font-bold">
                데이터 소스 연결하기
              </div>
            </div>
          </div>

          <.live_component
            module={CarrierWeb.Components.DataSourceNew}
            id="data_source_new"
            flash={@flash}
            org={@org}
            onsuccess={fn data_source -> send(@self, {:data_source_created, data_source}) end}
          />
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_info({:data_source_created, %DataSource{} = data_source}, socket) do
    redirect_path = ~p"/app/reports/new2?data_source_id=#{data_source}"

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
