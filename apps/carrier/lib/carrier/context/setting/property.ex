defmodule Carrier.Setting.Property do
  use Carrier.Schema

  @primary_key false
  schema "properties" do
    field :key, :string, primary_key: true
    field :type, Ecto.Enum, values: [:integer, :float, :string, :boolean, :list, :map]
    field :value, Carrier.Type.Any
  end

  def get(key) do
    __MODULE__
    |> where([p], p.key == ^key)
  end
end
