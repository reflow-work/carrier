defmodule Carrier.Core.Nillable do
  def map(nil, _fun), do: nil
  def map(not_nil, fun) when is_function(fun, 1), do: fun.(not_nil)

  def fallback(nil, value), do: value
  def fallback(not_nil, _value), do: not_nil

  def run(target, nil, _fun), do: target
  def run(target, _not_nil, fun) when is_function(fun, 1), do: target |> fun.()
  def run(target, not_nil, fun) when is_function(fun, 2), do: target |> fun.(not_nil)
end
