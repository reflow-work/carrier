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
  def render(assigns) do
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

      <div :if={@multiple} class="mt-4 space-y-2">
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
  def handle_event("search", %{"keyword" => keyword}, socket) do
    socket =
      socket
      |> assign(:keyword, keyword)
      |> assign_selectable_items()
      |> assign_show_selectable_items(true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select", %{"value" => selected_item_value}, socket) do
    selected_item =
      socket.assigns.items
      |> Enum.find(&(&1.value == selected_item_value))

    socket =
      socket
      |> select_item(selected_item)
      |> assign_keyword_unless_multiple(selected_item.label)
      |> assign_selectable_items()
      |> assign_show_selectable_items(socket.assigns.multiple)
      |> run_onchange()

    {:noreply, socket}
  end

  @impl true
  def handle_event("unselect", %{"index" => index}, socket) do
    socket =
      socket
      |> update(:selected_items, &(&1 |> List.delete_at(index)))
      |> assign_selectable_items()
      |> assign_show_selectable_items(false)
      |> run_onchange()

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_selectable_items", _params, socket) do
    socket =
      socket
      |> assign_show_selectable_items(true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_selectable_items", _params, socket) do
    socket =
      socket
      |> assign_show_selectable_items(false)

    {:noreply, socket}
  end

  defp normalize_items(items) do
    items
    |> Enum.map(fn {label, value} -> %{label: label, value: value} end)
  end

  defp select_item(socket, selected_item) do
    case socket.assigns.multiple do
      true ->
        socket
        |> update(:selected_items, &(&1 ++ [selected_item]))

      false ->
        socket
        |> assign(:selected_items, [selected_item])
    end
  end

  defp assign_show_selectable_items(socket, show) do
    case Blankable.blank?(socket.assigns.keyword) do
      true ->
        socket
        |> assign(:show_selectable_items, false)

      false ->
        socket
        |> assign(:show_selectable_items, show)
    end
  end

  defp assign_selectable_items(socket) do
    case Blankable.blank?(socket.assigns.keyword) do
      true ->
        socket
        |> assign(:selectable_items, [])

      false ->
        regex = socket.assigns.keyword |> String.trim() |> Regex.escape() |> Regex.compile!("i")

        selectable_items =
          socket.assigns.items
          |> handle_duplicated(socket.assigns.duplicatable, socket.assigns.selected_items)
          |> Stream.filter(fn item -> item.label =~ regex end)
          |> Stream.take(socket.assigns.max_search)
          |> Enum.to_list()

        socket
        |> assign(:selectable_items, selectable_items)
    end
  end

  defp assign_keyword_unless_multiple(socket, selected_item_label) do
    case socket.assigns.multiple do
      true -> socket
      false -> socket |> assign(:keyword, selected_item_label)
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
