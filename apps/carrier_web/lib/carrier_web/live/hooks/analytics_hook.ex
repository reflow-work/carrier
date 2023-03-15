defmodule CarrierWeb.AnalyticsHook do
  use CarrierWeb, :live_hook
  alias Carrier.Core.AnalyticsHelper

  def on_mount(:default, _params, _session, socket) do
    socket =
      case {connected?(socket), env()} do
        {true, :prod} ->
          socket
          |> init_analytics()
          |> attach_hook(:analytics_hook, :handle_params, fn
            _params, uri, socket ->
              page_name = AnalyticsHelper.get_page_name(uri)

              socket = socket |> log_event("view_#{page_name}")
              {:cont, socket}
          end)

        _ ->
          socket
      end

    {:cont, socket}
  end

  defp env() do
    Application.get_env(:carrier, :env)
  end
end
