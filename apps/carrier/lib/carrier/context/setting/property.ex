defmodule Carrier.Setting.Property do
  use Carrier.Schema

  @primary_key false
  schema "properties" do
    field :key, :string, primary_key: true
    field :type, Ecto.Enum, values: [:integer, :float, :string, :boolean, :list, :map, :datetime]
    field :value, Carrier.Type.Any
  end

  def get(key) do
    __MODULE__
    |> where([p], p.key == ^key)
  end

  def get_value_by_type(%__MODULE__{type: :datetime, value: value}) do
    {:ok, datetime, _} = DateTime.from_iso8601(value)

    datetime
  end

  def get_value_by_type(%__MODULE__{value: value}) do
    value
  end
end
