defmodule Carrier.Setting.FeatureFlag do
  use Carrier.Schema

  schema "feature_flags" do
    field :key, :string
    field :description, :string

    timestamps()
    field :deleted_at, :utc_datetime_usec
  end
end
