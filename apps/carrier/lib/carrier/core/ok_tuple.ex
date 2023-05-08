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

  def map({:ok, result}, fun) do
    fun.(result)
  end

  def map(error, _fun) do
    error
  end
end
