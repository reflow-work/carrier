defmodule CarrierWeb.DataSourceHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets
  alias Carrier.Secrets.DataSource

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_data_sources() do
      [%DataSource{} = data_source] ->
        {:cont, socket |> assign(:data_source, data_source)}

      _ ->
        socket = socket |> push_navigate(to: Routes.data_source_new_path(socket, :new))

        {:halt, socket}
    end
  end
end
