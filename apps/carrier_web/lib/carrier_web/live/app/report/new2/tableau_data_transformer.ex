defmodule CarrierWeb.App.ReportLive.New2.TableauDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Secrets
  alias CarrierWeb.App.ReportLive.New2.TableauView
  alias Carrier.Data.Source.Tableau

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_views, [])

    {:ok, socket}
  end

  # init
  @impl true
  def update(%{data_source: %DataSource{conn_info: %ConnInfo{} = conn_info}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_async(
        :views,
        fn ->
          {:ok, tableau_views} =
            conn_info
            |> ConnInfo.to_credentials()
            |> Tableau.list_views()

          tableau_views
        end,
        __MODULE__
      )

    {:ok, socket}
  end

  # update views
  @impl true
  def update(assigns, socket) do
    {selected_view_ids, assigns} = assigns |> Map.pop(:selected_view_ids, [])

    selected_views =
      selected_view_ids
      |> Enum.map(fn selected_view_id ->
        Enum.find(socket.assigns.views.value, fn %{id: id} -> id == selected_view_id end)
      end)

    socket =
      socket
      |> assign(assigns)
      |> assign(:selected_views, selected_views)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="Tableau View 선택하기" />
            <p class="mt-2">Tableau 에서 불러올 View 를 선택해주세요.</p>
          </div>

          <div class="max-w-md">
            <.icon :if={@views.loading?} name="hero-arrow-path" class="mt-4 w-6 h-6 animate-spin" />
            <.live_component
              :if={!@views.loading?}
              module={Search}
              id="tableau_view_selector"
              label="View 이름"
              label_align={:left}
              position={:top}
              items={
                @views.value |> Enum.map(fn %{id: id, full_name: full_name} -> {full_name, id} end)
              }
              max_search={7}
              max_select={3}
              onchange={
                fn selected_view_ids ->
                  send_update(__MODULE__, id: @id, selected_view_ids: selected_view_ids)
                end
              }
            />
          </div>
        </.card>
        <.card>
          <.live_component
            :for={%Tableau.View{id: id} = selected_view <- @selected_views}
            module={TableauView}
            id={id}
            data_source={@data_source}
            view={selected_view}
          />
        </.card>
      </.card_container>
    </div>
    """
  end
end
