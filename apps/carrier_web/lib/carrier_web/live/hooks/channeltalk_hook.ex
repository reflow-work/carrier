defmodule CarrierWeb.ChanneltalkHook do
  use CarrierWeb, :live_hook
  import CarrierWeb.ChanneltalkHelper

  def on_mount(:default, _params, _session, socket) do
    socket = socket |> boot_channeltalk()

    {:cont, socket}
  end
end
