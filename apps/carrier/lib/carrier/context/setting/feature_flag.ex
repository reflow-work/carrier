defmodule Carrier.Setting.FeatureFlag do
  use Carrier.Schema

  schema "feature_flags" do
    field :key, :string
    field :description, :string
    field :value, :boolean, read_after_writes: true

    timestamps()
    field :deleted_at, :utc_datetime_usec
  end

  def get_by_key(key) do
    __MODULE__
    |> where([ff], ff.key == ^key)
  end
end
