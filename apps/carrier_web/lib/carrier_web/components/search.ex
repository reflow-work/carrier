defmodule CarrierWeb.Components.Search do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:keyword, "")
      |> assign(:show_selectable_items, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {items, assigns} = assigns |> Map.pop(:items)

    socket =
      socket
      |> assign(assigns)
      |> assign(:items, normalize_items(items))
      |> assign(:selectable_items, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={%{}}>
        <div class="relative">
          <.input
            type="text"
            name="keyword"
            value={@keyword}
            phx-target={@myself}
            phx-change="search"
            phx-focus="show_selectable_items"
            phx-click-away="hide_selectable_items"
          />
          <div
            :if={@show_selectable_items}
            class="absolute w-full bg-white rounded-md shadow cursor-pointer divide-y z-50"
          >
            <div :for={selectable_item <- @selectable_items} class="px-4 py-2">
              <%= selectable_item.label %>
            </div>
          </div>
        </div>
        <!-- for disabling submit by enter -->
        <:actions>
          <.button class="hidden" disabled></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"keyword" => keyword}, socket) do
    socket =
      case keyword |> String.trim() do
        "" ->
          socket
          |> assign(:show_selectable_items, false)
          |> assign(:selectable_items, [])

        trimmed_keyword ->
          regex = trimmed_keyword |> Regex.escape() |> Regex.compile!("i")

          selectable_items =
            socket.assigns.items
            |> Enum.filter(fn item -> item.label =~ regex end)

          socket
          |> assign(:show_selectable_items, true)
          |> assign(:selectable_items, selectable_items)
      end

    socket =
      socket
      |> assign(:keyword, keyword)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_selectable_items", _params, socket) do
    socket =
      socket
      |> assign(:show_selectable_items, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_selectable_items", _params, socket) do
    socket =
      socket
      |> assign(:show_selectable_items, false)

    {:noreply, socket}
  end

  defp normalize_items(items) do
    items
    |> Enum.map(fn {label, value} -> %{label: label, value: value} end)
  end
end
