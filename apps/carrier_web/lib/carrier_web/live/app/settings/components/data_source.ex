defmodule CarrierWeb.App.SettingsLive.Components.DataSource do
  use CarrierWeb, :live_component
  alias Carrier.Integrations
  alias Carrier.Integrations.DataSource
  alias Carrier.Setting
  alias CarrierWeb.Components.{DataSourceNew, DataSourceEdit}

  @impl true
  def mount(socket) do
    max_data_source_count = Setting.Super.get_property_value("max_data_source_count", 3)

    socket =
      socket
      |> assign(:data_sources, [])
      |> assign(:selected_data_source, nil)
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
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={data_source <- @data_sources} class="hover">
                    <td><%= data_source.name %></td>
                    <td><%= DataSource.transl_source(data_source.source) %></td>
                    <td>
                      <.button
                        :if={data_source.source == :tableau and !data_source.demo}
                        phx-target={@myself}
                        phx-click={
                          JS.push("edit_data_source", value: %{data_source_id: data_source.id})
                        }
                      >
                        수정하기
                      </.button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </.card>
      </.card_container>

      <.modal id="new_data_source_modal" title="데이터 소스 추가">
        <.live_component
          module={DataSourceNew}
          id="data_source_new"
          org={@org}
          onsuccess={fn data_source -> send_update(__MODULE__, id: @id, data_source: data_source) end}
        />
      </.modal>
      <.modal :if={@selected_data_source} id="edit_data_source_modal" title="데이터 소스 수정">
        <.live_component
          module={DataSourceEdit}
          id="data_source_edit"
          data_source={@selected_data_source}
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
      |> update(:data_sources, fn data_sources ->
        index =
          data_sources
          |> Enum.find_index(&(&1.id == data_source.id))

        case index do
          nil -> [data_source | data_sources]
          index -> data_sources |> List.replace_at(index, data_source)
        end
      end)
      |> hide_modal_from_server("new_data_source_modal")
      |> hide_modal_from_server("edit_data_source_modal")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("edit_data_source", %{"data_source_id" => data_source_id}, socket) do
    selected_data_source =
      socket.assigns.data_sources
      |> Enum.find(&(&1.id == data_source_id))

    socket =
      socket
      |> assign(:selected_data_source, selected_data_source)
      |> show_modal_from_server("edit_data_source_modal")

    {:noreply, socket}
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
