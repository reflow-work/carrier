defmodule CarrierWeb.FlashHook do
  @moduledoc """
  https://elixirforum.com/t/liveview-flash-assigns-not-available-in-child-livecomponent/29558/9
  """

  use CarrierWeb, :live_hook

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> attach_hook(:flash, :handle_info, &handle_flash/2)

    Process.send_after(self(), :clear_flash, :timer.seconds(3))

    {:cont, socket}
  end

  def put_flash_for(socket, kind, message, opts \\ []) do
    timeout = opts |> Keyword.get(:timeout, :infinity)

    socket = Phoenix.LiveView.put_flash(socket, kind, message)

    case timeout do
      :infinity ->
        nil

      timeout when is_integer(timeout) ->
        Process.send_after(self(), :clear_flash, timeout)
    end

    socket
  end

  def push_flash(socket, key, msg, opts \\ []) do
    send(self(), {:flash, key, msg, opts})

    socket
  end

  defp handle_flash({:flash, key, msg, opts}, socket) do
    {:halt, put_flash_for(socket, key, msg, opts)}
  end

  defp handle_flash(:clear_flash, socket) do
    {:halt, clear_flash(socket)}
  end

  defp handle_flash(_otherwise, socket) do
    {:cont, socket}
  end
end
