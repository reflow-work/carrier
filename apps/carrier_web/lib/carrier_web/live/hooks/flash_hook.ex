defmodule CarrierWeb.FlashHook do
  @moduledoc """
  https://elixirforum.com/t/liveview-flash-assigns-not-available-in-child-livecomponent/29558/9
  """

  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :flash, :handle_info, &handle_flash/2)}
  end

  def push_flash(socket, key, msg, opts) do
    send(self(), {:flash, key, msg, opts})

    socket
  end

  defp handle_flash({:flash, key, msg, opts}, socket) do
    {:halt, put_flash_for(socket, key, msg, opts)}
  end

  defp handle_flash(_otherwise, socket) do
    {:cont, socket}
  end
end
