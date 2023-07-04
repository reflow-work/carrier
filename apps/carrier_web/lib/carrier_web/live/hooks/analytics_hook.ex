defmodule CarrierWeb.AnalyticsHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket =
      case {connected?(socket), env()} do
        {true, :prod} ->
          socket
          |> init_analytics()

        _ ->
          socket
      end

    {:cont, socket}
  end

  defp env() do
    Application.get_env(:carrier, :env)
  end
end
