defmodule CarrierWeb.CheckIntegrationHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, %{"org_id" => org_id}, socket) do
    case has_integration?(org_id) do
      true ->
        {:cont, socket}

      false ->
        socket = socket |> push_redirect(to: Routes.integration_new_path(socket, :new))

        {:halt, socket}
    end
  end

  defp has_integration?(_org_id) do
    false
  end
end
