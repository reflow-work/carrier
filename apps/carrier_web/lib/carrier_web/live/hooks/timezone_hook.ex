defmodule CarrierWeb.TimezoneHook do
  use CarrierWeb, :live_hook
  alias Carrier.Core.TimezoneHelper

  def on_mount(:default, _params, _session, socket) do
    timezone = get_timezone(socket)

    TimezoneHelper.put_timezone(timezone)

    socket =
      socket
      |> assign(:timezone, timezone)

    {:cont, socket}
  end

  defp get_timezone(socket) do
    get_connect_params(socket)["timezone"]
    |> TimezoneHelper.safe_timezone()
  end
end
