defmodule CarrierWeb.ChanneltalkHelper do
  import Phoenix.LiveView, only: [push_event: 3]
  alias Carrier.Core.Nillable

  def boot_channeltalk(socket) do
    socket
    |> push_event("channeltalk-boot", %{
      user_id: socket.assigns[:user_id] |> Nillable.map(&(&1 |> to_string()))
    })
  end
end
