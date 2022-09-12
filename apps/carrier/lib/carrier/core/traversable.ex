defmodule Carrier.Core.Traversable do
  def traverse(ok_tuple_list) when is_list(ok_tuple_list) do
    ok_tuple_list
    |> Enum.reduce_while({:ok, []}, fn ok_tuple, {:ok, acc} ->
      case ok_tuple do
        :ok -> {:cont, {:ok, [nil | acc]}}
        {:ok, result} -> {:cont, {:ok, [result | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, reveresed_results} -> {:ok, Enum.reverse(reveresed_results)}
      {:error, error} -> {:error, error}
    end
  end
end
