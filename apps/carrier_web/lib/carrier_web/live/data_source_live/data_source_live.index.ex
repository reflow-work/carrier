defmodule CarrierWeb.DataSourceLive.Index do
  use CarrierWeb, :live_view
  alias Carrier.Secrets.DataSource

  on_mount(CarrierWeb.DataSourceHook)

  @max_data_source_count 3

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:max_data_source_count, @max_data_source_count)
      |> assign(
        :is_disabled_to_create_new_data_source,
        socket.assigns.data_sources |> Enum.count() >= @max_data_source_count
      )

    {:ok, socket}
  end

  defp transl_data_source_source(%DataSource{source: source}) do
    case source do
      :postgres -> "PostgreSQL"
      :mysql -> "MySQL"
      :bigquery -> "Google BigQuery"
      :athena -> "AWS Athena"
    end
  end
end
