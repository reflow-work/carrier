defmodule Carrier.Migration do
  defmacro __using__([]) do
    quote do
      use Ecto.Migration
      import unquote(__MODULE__)
    end
  end

  import Ecto.Migration

  def add_tstz() do
    add(:created_at, :timestamptz, null: false, default: fragment("now()"))
    add(:updated_at, :timestamptz, null: false, default: fragment("now()"))
  end
end
