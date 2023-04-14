defmodule CarrierWeb.TimezoneHook do
  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:timezone, get_timezone(socket))

    {:cont, socket}
  end

  defp get_timezone(socket) do
    case get_connect_params(socket)["timezone"] do
      nil -> "UTC"
      "Etc/Unknown" -> "UTC"
      timezone -> timezone
    end
  rescue
    _ -> "UTC"
  end
end
