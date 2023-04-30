defmodule CarrierWeb.Components.Search do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:keyword, "")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={%{}}>
        <.input type="text" name="keyword" value={@keyword} phx-target={@myself} phx-change="search" />
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
      socket
      |> assign(:keyword, keyword)

    {:noreply, socket}
  end
end
