defmodule CarrierWeb.CheckIntegrationHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets

  def on_mount(:default, _params, _session, socket) do
    case has_integration?() do
      true ->
        {:cont, socket}

      false ->
        socket = socket |> push_redirect(to: Routes.integration_new_path(socket, :new))

        {:halt, socket}
    end
  end

  defp has_integration?() do
    case Secrets.list_integrations() do
      [_ | _] -> true
      [] -> false
    end
  end
end
