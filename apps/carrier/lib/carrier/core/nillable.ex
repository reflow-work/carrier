defmodule Carrier.Core.Nillable do
  def map(nil, _fun), do: nil
  def map(not_nil, fun), do: fun.(not_nil)

  def fallback(nil, value), do: value
  def fallback(not_nil, _value), do: not_nil
end
