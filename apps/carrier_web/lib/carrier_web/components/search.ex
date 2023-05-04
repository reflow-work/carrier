defmodule CarrierWeb.Components.Search do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      # external
      |> assign(:label, nil)
      |> assign(:label_align, nil)
      |> assign(:position, :bottom)
      |> assign(:max_search, 5)
      |> assign(:multiple, false)
      |> assign(:max_select, nil)
      |> assign(:duplicatable, false)
      |> assign(:placeholder, nil)
      # internal
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
      |> assign(:selected_items, [])

    {:ok, socket}
  end

  @impl true
  def render(%{multiple: true} = assigns) do
    ~H"""
    <div>
      <.simple_form for={%{}}>
        <div class="relative">
          <.input
            type="text"
            name="keyword"
            label={@label}
            label_align={@label_align}
            placeholder={@placeholder}
            value={@keyword}
            phx-target={@myself}
            phx-change="search"
            phx-focus="show_selectable_items"
            phx-click-away="hide_selectable_items"
          >
            <:icon>
              <.icon name="hero-magnifying-glass" />
            </:icon>
          </.input>
          <div
            :if={@show_selectable_items && @max_select > @selected_items |> Enum.count()}
            class={[
              "absolute w-full bg-white rounded-md shadow cursor-pointer divide-y z-50",
              @position == :top && "bottom-12"
            ]}
          >
            <div
              :for={selectable_item <- @selectable_items}
              class="px-4 py-2 hover:bg-gray-100"
              phx-target={@myself}
              phx-click={JS.push("select", value: %{value: selectable_item.value})}
            >
              <%= selectable_item.label %>
            </div>

            <div :if={@selectable_items |> Enum.empty?()} class="px-4 py-2">
              검색 결과가 없습니다.
            </div>
          </div>
        </div>
        <!-- for disabling submit by enter -->
        <.button class="hidden" disabled></.button>
      </.simple_form>

      <div class="mt-4 space-y-2">
        <p :if={@max_select}>
          최대 <span class="font-semibold"><%= @max_select %></span> 개까지 선택할 수 있습니다.
        </p>
        <div :for={{selected_item, i} <- @selected_items |> Enum.with_index()}>
          <.icon
            name="hero-x-circle"
            class="mr-2 w-6 h-6 cursor-pointer"
            phx-target={@myself}
            phx-click={JS.push("unselect", value: %{index: i})}
          /><%= selected_item.label %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def render(%{multiple: false} = assigns) do
    ~H"""
    <div>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"keyword" => keyword}, socket) do
    socket =
      socket
      |> assign(:keyword, keyword)
      |> assign_selectable_items()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"value" => value}, socket) do
    selected_item =
      socket.assigns.items
      |> Enum.find(&(&1.value == value))

    socket =
      socket
      |> update(:selected_items, &(&1 ++ [selected_item]))
      |> assign_selectable_items()
      |> run_onchange()

    {:noreply, socket}
  end

  @impl true
  def handle_event("unselect", %{"index" => index}, socket) do
    socket =
      socket
      |> update(:selected_items, &(&1 |> List.delete_at(index)))
      |> assign_selectable_items()
      |> run_onchange()

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_selectable_items", _params, socket) do
    socket =
      case socket.assigns.keyword |> String.trim() do
        "" ->
          socket

        _ ->
          socket
          |> assign(:show_selectable_items, true)
      end

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

  defp assign_selectable_items(socket) do
    case socket.assigns.keyword |> String.trim() do
      "" ->
        socket
        |> assign(:show_selectable_items, false)
        |> assign(:selectable_items, [])

      trimmed_keyword ->
        regex = trimmed_keyword |> Regex.escape() |> Regex.compile!("i")

        selectable_items =
          socket.assigns.items
          |> handle_duplicated(socket.assigns.duplicatable, socket.assigns.selected_items)
          |> Stream.filter(fn item -> item.label =~ regex end)
          |> Stream.take(socket.assigns.max_search)
          |> Enum.to_list()

        socket
        |> assign(:show_selectable_items, true)
        |> assign(:selectable_items, selectable_items)
    end
  end

  defp handle_duplicated(items, false, selected_items) do
    items |> Stream.reject(fn item -> item in selected_items end)
  end

  defp handle_duplicated(items, true, _selected_items) do
    items
  end

  defp run_onchange(socket) do
    socket.assigns.selected_items
    |> Enum.map(& &1.value)
    |> socket.assigns.onchange.()

    socket
  end
end
