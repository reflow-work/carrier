defmodule CarrierWeb.AssignHelper do
  import Phoenix.LiveView, only: [connected?: 1, send_update: 2]
  import Phoenix.Component, only: [assign: 3]

  def assign_async(socket, key, fun, live_component_module \\ nil)
      when is_atom(key) and (is_function(fun, 0) or is_function(fun, 1)) do
    case connected?(socket) do
      true ->
        pid = self()

        Task.start(fn ->
          result = call_function(socket, fun)

          live_component_info =
            case live_component_module do
              nil -> nil
              live_component_module -> %{module: live_component_module, id: socket.assigns.id}
            end

          send(pid, {:assign, {key, result, live_component_info}})
        end)

        socket
        |> assign(key, %{loading?: true, value: nil})

      false ->
        socket
    end
  end

  def handle_async_assigns({:assign, {key, value, live_component_info}}, socket) do
    case live_component_info do
      # LiveView
      nil ->
        case socket.assigns |> Map.has_key?(key) do
          true ->
            {:ok, socket |> assign(key, %{loading?: false, value: value})}

          false ->
            {:error, socket}
        end

      # LiveComponent
      %{module: module, id: id} ->
        send_update(module, %{
          :id => id,
          key => %{loading?: false, value: value}
        })
    end
  end

  defp call_function(_socket, fun) when is_function(fun, 0) do
    fun.()
  end

  defp call_function(socket, fun) when is_function(fun, 1) do
    fun.(socket.assigns)
  end
end
