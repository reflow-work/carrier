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

  def traverse_all(ok_tuple_list) when is_list(ok_tuple_list) do
    ok_tuple_list
    |> Enum.reduce({:ok, []}, fn
      ok_tuple, {:ok, acc} ->
        case ok_tuple do
          :ok -> {:ok, [nil | acc]}
          {:ok, result} -> {:ok, [result | acc]}
          {:error, error} -> {:error, [error]}
        end

      ok_tuple, {:error, acc} ->
        case ok_tuple do
          :ok -> {:error, acc}
          {:ok, _result} -> {:error, acc}
          {:error, error} -> {:error, [error | acc]}
        end
    end)
    |> case do
      {:ok, reveresed_results} -> {:ok, Enum.reverse(reveresed_results)}
      {:error, reveresed_results} -> {:error, Enum.reverse(reveresed_results)}
    end
  end
end
