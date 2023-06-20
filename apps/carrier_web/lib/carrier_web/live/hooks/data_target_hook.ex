defmodule CarrierWeb.DataTargetHook do
  use CarrierWeb, :live_hook
  use Carrier.Integrations

  def on_mount(:default, _params, _session, socket) do
    case Integrations.list_data_targets() do
      [%DataTarget{needs_update: false} = data_target] = data_targets ->
        {:cont,
         socket |> assign(:data_target, data_target) |> assign(:data_targets, data_targets)}

      [%DataTarget{needs_update: true} = data_target] ->
        socket = socket |> push_navigate(to: ~p"/app/data-targets/#{data_target}/edit")

        {:halt, socket}

      _ ->
        socket = socket |> push_navigate(to: ~p"/app/data-targets/new")

        {:halt, socket}
    end
  end
end
