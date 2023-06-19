defmodule CarrierWeb.AssignHelper do
  import Phoenix.LiveView, only: [connected?: 1, send_update: 2]
  import Phoenix.Component, only: [assign: 3]

  def assign_async(socket, key, fun, live_component_module \\ nil)
      when is_atom(key) and (is_function(fun, 0) or is_function(fun, 1)) do
    if connected?(socket) do
      pid = self()

      Task.start(fn ->
        result = call_function(socket, fun)

        live_component_info =
          case live_component_module do
            nil -> nil
            live_component_module -> %{module: live_component_module, id: socket.assigns.id}
          end

        send(pid, {:assign_async, {key, result, live_component_info}})
      end)
    end

    socket
    |> assign(key, init_value())
  end

  def handle_async_assigns({:assign_async, {key, result, live_component_info}}, socket) do
    async_value = convert_result(result)

    case live_component_info do
      # LiveView
      nil ->
        case socket.assigns |> Map.has_key?(key) do
          true ->
            {:ok, socket |> assign(key, async_value)}

          false ->
            {:error, socket}
        end

      # LiveComponent
      %{module: module, id: id} ->
        send_update(module, %{
          :id => id,
          key => async_value
        })
    end
  end

  @dictionary_keys [Carrier.TenantRepo.tenant_key(), Carrier.Core.TimezoneHelper.timezone_key()]
  def assign_concurrent(socket, key_fun_map) when is_map(key_fun_map) do
    dictionary =
      @dictionary_keys
      |> Enum.map(&{&1, Process.get(&1)})

    key_fun_map
    |> Task.async_stream(fn {key, fun} ->
      dictionary
      |> Enum.each(fn {key, value} -> Process.put(key, value) end)

      {key, call_function(socket, fun)}
    end)
    |> Enum.reduce(socket, fn
      {:ok, {key, {:ok, result}}}, socket ->
        socket |> assign(key, result)

      _, socket ->
        socket
    end)
  end

  defp call_function(_socket, nil), do: nil

  defp call_function(_socket, fun) when is_function(fun, 0) do
    fun.()
  end

  defp call_function(socket, fun) when is_function(fun, 1) do
    fun.(socket.assigns)
  end

  defp init_value() do
    %{loading?: true, valid?: false, value: nil, error: nil}
  end

  defp convert_result({:ok, value}) do
    %{loading?: false, valid?: true, value: value, error: nil}
  end

  defp convert_result({:error, error}) do
    %{loading?: false, valid?: false, value: nil, error: error}
  end
end
