defmodule Carrier.Setting.FeatureFlagValue do
  use Carrier.Schema
  alias Carrier.Setting.FeatureFlag

  schema "feature_flag_values" do
    belongs_to :key, FeatureFlag, references: :key, type: :string

    field :org_id, :integer
    field :value, :boolean
  end
end
