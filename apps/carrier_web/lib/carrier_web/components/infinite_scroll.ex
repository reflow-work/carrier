defmodule CarrierWeb.Components.InfiniteScroll do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(loader: nil)
      |> assign(next_cursor: nil, size: 30, last?: false)
      # for call updated of js hook
      |> assign(page: 0)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> load_data()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="infinite-scroll-marker"
      phx-hook="InfiniteScroll"
      data-page={@page}
      class="w-full text-center"
    >
      <.loading :if={!@last?} />
    </div>
    """
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    socket =
      case socket.assigns.last? do
        false -> socket |> load_data()
        true -> socket
      end

    {:noreply, socket}
  end

  defp load_data(socket) do
    {:ok, %{entries: entries, meta: meta}} =
      socket
      |> page_params()
      |> socket.assigns.loader.()

    send(self(), {:loaded_more, entries})

    socket
    |> assign(next_cursor: meta.next_cursor, last?: meta.last?)
    |> update(:page, &(&1 + 1))
  end

  defp page_params(socket) do
    socket.assigns
    |> Map.take([:next_cursor, :size])
  end
end
