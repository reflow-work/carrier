defmodule Carrier.Core.OkTuple do
  def unwrap(tuple, fallback \\ nil)

  def unwrap({:ok, result}, _fallback) do
    result
  end

  def unwrap({:error, _}, fallback) do
    fallback
  end

  def unwrap(:error, fallback) do
    fallback
  end
end
