defmodule CarrierWeb.App.ReportLive.New2.TableauDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias CarrierWeb.App.ReportLive.New2.TableauView
  alias CarrierWeb.App.ReportLive.New2.DataSourceInfoParams
  alias Carrier.Data.Source.Tableau
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_views, [])

    {:ok, socket}
  end

  # init
  @impl true
  def update(%{data_source: %DataSource{} = data_source} = assigns, socket) do
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

    validate_and_send_data_source_info_form(socket)

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
            <.card_title title="Tableau View 선택하기" />
            <p class="mt-2">Tableau 에서 불러올 View 를 선택해주세요.</p>
          </div>

          <div class="max-w-md">
            <.loading :if={@views.loading?} />
            <.live_component
              :if={!@views.loading?}
              module={Search}
              id="tableau_view_selector"
              label="View 이름"
              label_align={:left}
              placeholder="View 이름으로 검색해주세요."
              position={:top}
              items={
                @views.value |> Enum.map(fn %{id: id, full_name: full_name} -> {full_name, id} end)
              }
              multiple={true}
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
          <p :if={@selected_views |> Enum.empty?()}>Tablea View 를 선택해주세요</p>
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

  defp validate_and_send_data_source_info_form(socket) do
    data_source_info_input = %{
      data_source_id: socket.assigns.data_source.id,
      source: :tableau,
      params: %{
        views:
          socket.assigns.selected_views
          |> Enum.map(fn %Tableau.View{id: id, full_name: full_name} ->
            %{id: id, full_name: full_name}
          end)
      }
    }

    data_source_info_form =
      Params.to_form(%DataSourceInfoParams{}, data_source_info_input, as: :data_source_info)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
