defmodule CarrierWeb.App.SettingsLive do
  use CarrierWeb, :live_view
  use Carrier.{Billing, Payments}
  alias Carrier.Secrets.DataSource
  alias Carrier.Setting

  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    max_data_source_count = Setting.Super.get_property_value("max_data_source_count", 3)

    socket =
      socket
      |> assign(:selected_menu, :account)
      |> assign(:max_data_source_count, max_data_source_count)
      |> assign(
        :is_disabled_to_create_new_data_source,
        socket.assigns.data_sources |> Enum.count() >= max_data_source_count
      )

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

  defp transl_data_source_source(%DataSource{source: source}) do
    case source do
      :postgres -> "PostgreSQL"
      :mysql -> "MySQL"
      :bigquery -> "Google BigQuery"
      :athena -> "AWS Athena"
      :tableau -> "Tableau Cloud"
    end
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
