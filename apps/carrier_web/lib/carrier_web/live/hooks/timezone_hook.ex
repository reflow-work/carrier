defmodule CarrierWeb.TimezoneHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:timezone, get_connect_params(socket)["timezone"] || "UTC")

    {:cont, socket}
  end
end
