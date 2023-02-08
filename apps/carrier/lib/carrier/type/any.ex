defmodule Carrier.Type.Any do
  use Ecto.Type

  def type, do: :any

  def cast(value), do: {:ok, value}

  def load(value), do: {:ok, value}

  def dump(value), do: {:ok, value}
end
