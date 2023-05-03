defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_menu, :account)

    {:ok, socket}
  end

  @impl true
  def handle_event("smartlook_anonymize", _params, socket) do
    socket =
      socket
      |> push_event("smartlook_anonymize", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_menu", %{"menu" => menu}, socket) do
    socket =
      socket
      |> assign(:selected_menu, String.to_existing_atom(menu))

    {:noreply, socket}
  end

  attr :menu, :atom, required: true
  attr :selected_menu, :atom, required: true

  defp menu(assigns) do
    ~H"""
    <div
      class={[
        "rounded-md p-2 cursor-pointer hover:bg-gray-100",
        @selected_menu == @menu && "!bg-gray-200"
      ]}
      phx-click="select_menu"
      phx-value-menu={@menu |> to_string()}
    >
      <%= @menu |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
    </div>
    """
  end
end
