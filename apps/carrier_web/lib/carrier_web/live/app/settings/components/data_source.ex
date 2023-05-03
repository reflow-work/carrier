defmodule CarrierWeb.App.SettingsLive.Components.DataSource do
  use CarrierWeb, :live_component
  alias Carrier.Secrets
  alias Carrier.Secrets.DataSource
  alias Carrier.Setting

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
            <.link
              navigate={~p"/app/data-sources/new"}
              class={[
                "btn",
                "btn-primary",
                if(@is_disabled_to_create_new_data_source, do: "btn-disabled")
              ]}
            >
              새 데이터 소스 생성
            </.link>

            <%= if @is_disabled_to_create_new_data_source do %>
              <div>
                데이터 소스는 최대 <%= @max_data_source_count %>개까지 등록 가능합니다
              </div>
            <% end %>
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
                  <%= for data_source <- @data_sources do %>
                    <tr class="hover">
                      <td><%= data_source.name %></td>
                      <td><%= transl_data_source_source(data_source) %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </section>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp load_data_sources(socket) do
    case Secrets.list_data_sources() do
      data_sources ->
        socket |> assign(:data_sources, data_sources)

      {:error, _} ->
        socket
    end
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
end
