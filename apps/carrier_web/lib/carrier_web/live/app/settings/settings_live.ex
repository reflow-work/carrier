defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_menu, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      case params["selected_menu"] do
        nil ->
          default_menu = @menus |> List.first()

          socket
          |> push_patch(to: ~p"/app/settings?selected_menu=#{default_menu}")

        selected_menu_str ->
          socket
          |> assign(:selected_menu, String.to_existing_atom(selected_menu_str))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("smartlook_anonymize", _params, socket) do
    socket =
      socket
      |> push_event("smartlook_anonymize", %{})

    {:noreply, socket}
  end

  attr :menu, :atom, required: true
  attr :selected_menu, :atom, required: true

  defp menu(assigns) do
    ~H"""
    <.link patch={~p"/app/settings?selected_menu=#{@menu}"}>
      <div class={[
        "rounded-md p-2 cursor-pointer hover:bg-gray-100",
        @selected_menu == @menu && "!bg-gray-200"
      ]}>
        <%= @menu |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
      </div>
    </.link>
    """
  end
end
