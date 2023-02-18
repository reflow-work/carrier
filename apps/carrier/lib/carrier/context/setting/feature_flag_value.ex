defmodule Carrier.Setting.FeatureFlagValue do
  use Carrier.Schema
  alias Carrier.Setting.FeatureFlag

  schema "feature_flag_values" do
    belongs_to :feature_flag, FeatureFlag

    field :org_id, :integer
    field :feature_flag_key, :string
    field :value, :boolean
  end

  def get_by_feature_flag_key(feature_flag_key) do
    __MODULE__
    |> where([ffv], ffv.feature_flag_key == ^feature_flag_key)
  end
end
