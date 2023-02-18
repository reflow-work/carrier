defmodule CarrierWeb.DataSourceHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_data_sources() do
      [_ | _] = data_sources ->
        {:cont, socket |> assign(:data_sources, data_sources)}

      _ ->
        socket = socket |> push_navigate(to: Routes.data_source_new_path(socket, :new))

        {:halt, socket}
    end
  end
end
