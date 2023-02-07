defmodule Carrier.Setting.Property do
  use Carrier.Schema

  @primary_key false
  schema "properties" do
    field :key, :string, primary_key: true

    field :type, Ecto.Enum,
      values: [:integer, :string, :boolean, :decimal, :datetime, :list, :map]

    field :integer_value, :integer
    field :string_value, :string
    field :boolean_value, :boolean
    field :decimal_value, :decimal
    field :datetime_value, :utc_datetime
    field :list_value, {:array, :any}
    field :map_value, :map
  end

  def get(key) do
    __MODULE__
    |> where([p], p.key == ^key)
  end

  def get_typed_value(%__MODULE__{type: type} = struct) do
    case type do
      :integer -> struct.integer_value
      :string -> struct.string_value
      :boolean -> struct.boolean_value
      :decimal -> struct.decimal_value
      :datetime -> struct.datetime_value
      :list -> struct.list_value
      :map -> struct.map_value
    end
  end
end
