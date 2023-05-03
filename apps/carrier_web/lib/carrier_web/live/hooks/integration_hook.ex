defmodule CarrierWeb.IntegrationHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets
  alias Carrier.Secrets.DataTarget

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_integrations() do
      [%DataTarget{} = integration] ->
        {:cont, socket |> assign(:integration, integration)}

      _ ->
        socket = socket |> push_navigate(to: ~p"/app/integrations/new")

        {:halt, socket}
    end
  end
end
