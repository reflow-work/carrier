defmodule CarrierWeb.ChanneltalkHelper do
  import Phoenix.LiveView, only: [push_event: 3]
  alias Phoenix.LiveView.JS
  alias Carrier.Core.Nillable

  def boot_channeltalk(socket) do
    socket
    |> push_event("channeltalk-boot", %{
      user_id: socket.assigns[:user_id] |> Nillable.map(&(&1 |> to_string()))
    })
  end

  def open_channel_talk(socket) do
    socket
    |> push_event("channeltalk-open", %{})
  end

  def js_open_channel_talk(js \\ %JS{}) do
    js
    |> JS.dispatch("phx:channeltalk-open")
  end
end
