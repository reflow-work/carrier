defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view

  @menu_components [
    {:account, __MODULE__.Components.Account},
    {:billing, __MODULE__.Components.Billing},
    {:data_source, __MODULE__.Components.DataSource}
  ]

  @menus @menu_components |> Enum.map(fn {menu, _} -> menu end)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:menus, @menus)
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
  attr :selected?, :boolean, required: true

  defp menu(assigns) do
    ~H"""
    <.link patch={~p"/app/settings?selected_menu=#{@menu}"}>
      <div class={[
        "rounded-md p-2 cursor-pointer hover:bg-gray-100",
        @selected? && "!bg-gray-200"
      ]}>
        <%= @menu |> to_string() |> String.capitalize() |> String.replace("_", " ") %>
      </div>
    </.link>
    """
  end

  defp get_menu_module(menu) do
    @menu_components
    |> Enum.find_value(fn
      {^menu, module} -> module
      _ -> nil
    end)
  end
end
