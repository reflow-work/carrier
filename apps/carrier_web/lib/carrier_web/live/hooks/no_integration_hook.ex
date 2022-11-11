defmodule CarrierWeb.NoIntegrationHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_integrations() do
      [] ->
        {:cont, socket}

      _ ->
        socket = socket |> push_navigate(to: Routes.report_index_path(socket, :index))

        {:halt, socket}
    end
  end
end
