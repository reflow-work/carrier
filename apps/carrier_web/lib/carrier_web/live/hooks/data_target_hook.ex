defmodule CarrierWeb.DataTargetHook do
  use CarrierWeb, :live_hook
  alias Carrier.Integrations
  alias Carrier.Integrations.DataTarget

  def on_mount(:default, _params, _session, socket) do
    case Integrations.list_data_targets() do
      [%DataTarget{} = data_target] ->
        {:cont, socket |> assign(:data_target, data_target)}

      _ ->
        socket = socket |> push_navigate(to: ~p"/app/data-targets/new")

        {:halt, socket}
    end
  end
end
