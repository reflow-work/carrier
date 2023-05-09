defmodule Carrier.Core.Async do
  alias Carrier.TaskSupervisor

  @default_dictionary_keys [
    Carrier.TenantRepo.tenant_key(),
    Carrier.Core.TimezoneHelper.timezone_key()
  ]

  def map(enumerable, fun, opts \\ []) when is_function(fun, 1) do
    {dictionary_keys, opts} = opts |> Keyword.pop(:dictionary_keys, @default_dictionary_keys)
    dictionary_for_copy = get_dictionary(dictionary_keys)

    async_stream_opts = [on_timeout: :kill_task] |> Keyword.merge(opts)

    Task.Supervisor.async_stream(
      TaskSupervisor,
      enumerable,
      fn item ->
        put_dictionary(dictionary_for_copy)

        fun.(item)
      end,
      async_stream_opts
    )
    |> Enum.map(fn
      {:ok, result} -> {:ok, result}
      {:exit, reason} -> {:error, reason}
    end)
  end

  def run(fun, opts \\ []) when is_function(fun, 0) do
    dictionary_keys = opts |> Keyword.get(:dictionary_keys, @default_dictionary_keys)
    dictionary_for_copy = get_dictionary(dictionary_keys)

    Task.Supervisor.start_child(TaskSupervisor, fn ->
      put_dictionary(dictionary_for_copy)

      fun.()
    end)
  end

  defp get_dictionary(dictionary_keys) do
    dictionary_keys
    |> Enum.map(fn key -> {key, Process.get(key)} end)
  end

  defp put_dictionary(dictionary) do
    dictionary
    |> Enum.each(fn {key, value} -> Process.put(key, value) end)
  end
end
