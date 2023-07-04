defmodule CarrierWeb.App.SettingsLive.Components.DataSource do
  use CarrierWeb, :live_component
  alias Carrier.Integrations
  alias Carrier.Integrations.DataSource
  alias Carrier.Setting
  alias CarrierWeb.Components.DataSourceNew

  @impl true
  def mount(socket) do
    max_data_source_count = Setting.Super.get_property_value("max_data_source_count", 3)

    socket =
      socket
      |> assign(:data_sources, [])
      |> load_data_sources()

    socket =
      socket
      |> assign(:max_data_source_count, max_data_source_count)
      |> assign(
        :is_disabled_to_create_new_data_source,
        socket.assigns.data_sources |> Enum.count() >= max_data_source_count
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1">
      <.card_container class="space-y-4">
        <.card>
          <div class="flex justify-between">
            <.card_title title="데이터 소스 목록" />
            <.button
              type="button"
              class={["ml-2", @is_disabled_to_create_new_data_source && "btn-disabled"]}
              phx-click={
                js_log_event("click_new_data_source", %{page_name: "setting"})
                |> show_modal("new_data_source_modal")
              }
            >
              새 데이터 소스 추가
            </.button>

            <div :if={@is_disabled_to_create_new_data_source}>
              데이터 소스는 최대 <%= @max_data_source_count %>개까지 등록 가능합니다
            </div>
          </div>

          <section class="mt-6">
            <div class="overflow-x-auto">
              <table class="table w-full">
                <thead>
                  <tr>
                    <th>이름</th>
                    <th>소스</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={data_source <- @data_sources} class="hover">
                    <td><%= data_source.name %></td>
                    <td><%= DataSource.transl_source(data_source.source) %></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </.card>
      </.card_container>

      <.modal id="new_data_source_modal">
        <.live_component
          module={DataSourceNew}
          id="data_source_new"
          org={@org}
          flash={@flash}
          onsuccess={fn data_source -> send_update(__MODULE__, id: @id, data_source: data_source) end}
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def update(%{data_source: data_source}, socket) do
    socket =
      socket
      |> update(:data_sources, &[data_source | &1])
      |> hide_modal_from_server("new_data_source_modal")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    {:ok, socket}
  end

  defp load_data_sources(socket) do
    case Integrations.list_data_sources() do
      {:ok, data_sources} ->
        socket |> assign(:data_sources, data_sources)

      {:error, _} ->
        socket
    end
  end
end
