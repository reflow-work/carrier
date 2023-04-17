defmodule Carrier.Core.Applicable do
  def apply(value, fun) when is_function(fun, 1) do
    fun.(value)
  rescue
    FunctionClauseError -> value
  end
end
