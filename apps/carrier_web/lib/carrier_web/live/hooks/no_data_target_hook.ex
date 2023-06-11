defmodule CarrierWeb.NoDataTargetHook do
  use CarrierWeb, :live_hook
  use Carrier.Integrations

  def on_mount(:default, _params, _session, socket) do
    case Integrations.list_data_targets() do
      [%DataTarget{needs_update: false}] ->
        socket = socket |> push_navigate(to: ~p"/app/reports")

        {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end
end
