defmodule CarrierWeb.AnalyticsHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket = socket |> init_analytics()

    {:cont, socket}
  end
end
