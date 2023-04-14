defmodule CarrierWeb.TimezoneHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:timezone, get_timezone(socket))

    {:cont, socket}
  end

  defp get_timezone(socket) do
    timezone = get_connect_params(socket)["timezone"]

    case Timex.is_valid_timezone?(timezone) do
      true -> timezone
      false -> "UTC"
    end
  rescue
    _ -> "UTC"
  end
end
