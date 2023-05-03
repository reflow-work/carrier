defmodule CarrierWeb.NoDataTargetHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_data_targets() do
      [] ->
        {:cont, socket}

      _ ->
        socket = socket |> push_navigate(to: ~p"/app/reports")

        {:halt, socket}
    end
  end
end
