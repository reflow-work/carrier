defmodule CarrierWeb.IntegrationHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets
  alias Carrier.Secrets.Integration

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_integrations() do
      [%Integration{} = integration] ->
        {:cont, socket |> assign(:integration, integration)}

      false ->
        socket = socket |> push_redirect(to: Routes.integration_new_path(socket, :new))

        {:halt, socket}
    end
  end
end
