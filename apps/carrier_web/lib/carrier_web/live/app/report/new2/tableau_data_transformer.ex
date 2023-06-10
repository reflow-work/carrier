defmodule CarrierWeb.App.ReportLive.New2.TableauDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias CarrierWeb.App.ReportLive.New2.TableauView
  alias CarrierWeb.App.ReportLive.New2.DataSourceInfoParams
  alias Carrier.Data.Source.Tableau

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_view_ids, [])
      |> assign(:selected_views, [])

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
        :views,
        fn ->
          {:ok, tableau_views} =
            data_source
            |> DataSource.to_credentials()
            |> Tableau.list_views()

          tableau_views
        end,
        __MODULE__
      )

    socket =
      case data_source_info do
        nil ->
          socket

        %{params: %{views: views}} ->
          selected_view_ids = views |> Enum.map(& &1.id)

          socket
          |> assign(:selected_view_ids, selected_view_ids)
      end

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  # update by async update
  @impl true
  def update(%{views: views}, socket) do
    socket =
      socket
      |> assign(:views, views)

    if not (socket.assigns.selected_view_ids |> Enum.empty?()) do
      send_update(Search,
        id: "tableau_view_selector",
        selected_item_values: socket.assigns.selected_view_ids
      )
    end

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  # update by search
  @impl true
  def update(%{selected_view_ids: selected_view_ids}, socket) do
    selected_views =
      selected_view_ids
      |> Enum.map(fn selected_view_id ->
        Enum.find(socket.assigns.views.value, fn %{id: id} -> id == selected_view_id end)
      end)

    socket =
      socket
      |> assign(:selected_views, selected_views)

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
            <.card_title title="Tableau View" />
          </div>

          <div class="max-w-md">
            <.loading :if={@views.loading?} />
            <.live_component
              :if={!@views.loading?}
              module={Search}
              id="tableau_view_selector"
              placeholder="View 이름으로 검색해주세요"
              position={:top}
              items={
                @views.value |> Enum.map(fn %{id: id, full_name: full_name} -> {full_name, id} end)
              }
              multiple={true}
              onchange={
                fn selected_view_ids ->
                  send_update(__MODULE__, id: @id, selected_view_ids: selected_view_ids)
                end
              }
            />
          </div>
        </.card>
        <.card>
          <div class="space-y-8">
            <p :if={@selected_views |> Enum.empty?()}>Tablea View 를 선택해주세요</p>
            <.live_component
              :for={%Tableau.View{id: id} = selected_view <- @selected_views}
              module={TableauView}
              id={id}
              data_source={@data_source}
              view={selected_view}
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
      source: :tableau,
      params: %{
        views: socket.assigns.selected_views |> Enum.map(&Map.from_struct/1)
      }
    }

    data_source_info_form = DataSourceInfoParams.to_form(data_source_info_input)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
