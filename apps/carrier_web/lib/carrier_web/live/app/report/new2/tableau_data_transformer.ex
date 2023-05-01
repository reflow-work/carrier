defmodule CarrierWeb.App.ReportLive.New2.TableauDataTransformer do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:views, [
        %{id: "a", name: "D", full_name: "A / C / D"},
        %{id: "b", name: "X", full_name: "Z / Y / X"}
      ])
      |> assign(:selected_views, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {selected_view_ids, assigns} = assigns |> Map.pop(:selected_view_ids, [])

    selected_views =
      selected_view_ids
      |> Enum.map(fn selected_view_id ->
        Enum.find(socket.assigns.views, fn %{id: id} -> id == selected_view_id end)
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
        <.card>
          <div>
            <.card_title title="Tableau View 선택하기" />
            <p class="mt-2">Tableau 에서 불러올 View 를 선택해주세요.</p>
          </div>

          <div class="max-w-md">
            <.live_component
              module={Search}
              id="tableau_view_selector"
              items={@views |> Enum.map(fn %{id: id, full_name: full_name} -> {full_name, id} end)}
              onchange={
                fn selected_view_ids ->
                  send_update(__MODULE__, id: @id, selected_view_ids: selected_view_ids)
                end
              }
            />
          </div>
        </.card>
        <.card>
          <div :for={selected_view <- @selected_views}>
            <%= inspect(selected_view) %>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end
end
