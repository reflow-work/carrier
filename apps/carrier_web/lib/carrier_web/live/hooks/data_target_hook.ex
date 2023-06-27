defmodule CarrierWeb.DataTargetHook do
  use CarrierWeb, :live_hook
  use Carrier.Integrations

  def on_mount(:default, _params, _session, socket) do
    case Integrations.list_data_targets() do
      {:ok, [%DataTarget{needs_update: false} = data_target]} = data_targets ->
        {:cont,
         socket |> assign(:data_target, data_target) |> assign(:data_targets, data_targets)}

      {:ok, [%DataTarget{needs_update: true} = data_target]} ->
        socket = socket |> push_navigate(to: ~p"/app/data-targets/#{data_target}/edit")

        {:halt, socket}

      _ ->
        {:cont, socket |> assign(:data_target, nil) |> assign(:data_targets, [])}
    end
  end
end
