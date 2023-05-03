defmodule CarrierWeb.DataTargetHook do
  use CarrierWeb, :live_hook
  alias Carrier.Secrets
  alias Carrier.Secrets.DataTarget

  def on_mount(:default, _params, _session, socket) do
    case Secrets.list_data_targets() do
      [%DataTarget{} = data_target] ->
        {:cont, socket |> assign(:data_target, data_target)}

      _ ->
        socket = socket |> push_navigate(to: ~p"/app/data-targets/new")

        {:halt, socket}
    end
  end
end
