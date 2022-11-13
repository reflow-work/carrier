defmodule CarrierWeb.AnalyticsHook do
  use CarrierWeb, :live_hook

  alias Carrier.Core.AnalyticsHelper

  def on_mount(:default, _params, _session, socket) do
    env = Application.get_env(:carrier, :env)

    if env == :prod do
      socket = socket |> init_analytics()

      socket =
        attach_hook(socket, :analytics_hook, :handle_params, fn
          _params, uri, socket ->
            page_name = AnalyticsHelper.get_page_name(uri)

            socket = socket |> log_event("view_#{page_name}")
            {:cont, socket}
        end)

      {:cont, socket}
    end

    {:cont, socket}
  end
end
