defmodule CarrierWeb.App.ReportLive.New2.RedashDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias CarrierWeb.App.ReportLive.New2.{DataSourceInfoParams, RedashDashboard}
  alias Carrier.Data.Source.Redash

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_dashboard_ids, [])
      |> assign(:selected_dashboards, [])

    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{data_source: %DataSource{} = data_source, data_source_info: data_source_info} = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign_async(
        :dashboards,
        fn -> data_source |> Redash.list_dashboards() end,
        __MODULE__
      )

    socket =
      case data_source_info do
        nil ->
          socket

        %{params: %{dashboards: dashboards}} ->
          selected_dashboard_ids = dashboards |> Enum.map(& &1.id)

          socket
          |> assign(:selected_dashboard_ids, selected_dashboard_ids)
      end

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  # update by async update
  @impl true
  def update(%{dashboards: dashboards}, socket) do
    socket =
      socket
      |> assign(:dashboards, dashboards)

    if not (socket.assigns.selected_dashboard_ids |> Enum.empty?()) do
      send_update(Search,
        id: "redash_dashboard_selector",
        selected_item_values: socket.assigns.selected_dashboard_ids
      )
    end

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  # update by search
  @impl true
  def update(%{selected_dashboard_ids: selected_dashboard_ids}, socket) do
    selected_dashboards =
      selected_dashboard_ids
      |> Enum.map(fn selected_dashboard_id ->
        Enum.find(socket.assigns.dashboards.value, fn %{id: id} -> id == selected_dashboard_id end)
      end)

    socket =
      socket
      |> assign(:selected_dashboards, selected_dashboards)

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="2. 대시보드 데이터 설정" />
          </div>

          <div class="max-w-md">
            <.loading :if={@dashboards.loading?} />
            <.live_component
              :if={@dashboards.valid?}
              module={Search}
              id="redash_dashboard_selector"
              placeholder="Redash Dashboard 이름으로 검색해주세요"
              position={:top}
              items={
                @dashboards.value
                |> Enum.map(fn %{id: id, name: name} -> {name, id} end)
              }
              multiple={true}
              onchange={
                fn selected_dashboard_ids ->
                  send_update(__MODULE__, id: @id, selected_dashboard_ids: selected_dashboard_ids)
                end
              }
            />
            <.error :if={@dashboards.error}><%= @dashboards.error %></.error>
          </div>
          <hr class="my-4" />
          <div class="space-y-8">
            <p :if={@selected_dashboards |> Enum.empty?()}>Redash Dashboard 를 선택해주세요.</p>
            <div :if={@selected_dashboards |> Enum.any?()}>
              <p>Redash 정책으로 인해 Dashboard 미리보기를 가져오는데 몇 분의 시간이 소요될 수 있습니다.</p>
              <p>미리보기 로딩이 끝나지 않아도 리포트 테스트 발송 및 저장할 수 있습니다.</p>
            </div>
            <.live_component
              :for={%Redash.Dashboard{id: id} = selected_dashboard <- @selected_dashboards}
              module={RedashDashboard}
              id={id}
              data_source={@data_source}
              dashboard={selected_dashboard}
            />
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp validate_and_send_data_source_info_form(socket) do
    data_source_info_input = %{
      data_source_id: socket.assigns.data_source.id,
      source: :redash,
      params: %{
        dashboards: socket.assigns.selected_dashboards |> Enum.map(&Map.from_struct/1)
      }
    }

    data_source_info_form = DataSourceInfoParams.to_form(data_source_info_input)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
