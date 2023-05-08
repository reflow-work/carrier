defmodule Carrier.Core.Async do
  alias Carrier.TaskSupervisor

  def map(enumerable, fun, opts \\ []) when is_function(fun, 1) do
    opts = [on_timeout: :kill_task] |> Keyword.merge(opts)

    Task.Supervisor.async_stream(TaskSupervisor, enumerable, fun, opts)
    |> Enum.map(fn
      {:ok, result} -> {:ok, result}
      {:exit, reason} -> {:error, reason}
    end)
  end
end
