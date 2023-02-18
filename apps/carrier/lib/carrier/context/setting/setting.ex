defmodule Carrier.Setting do
  use Carrier.Core.Cache
  require Logger
  alias Carrier.Setting.FeatureFlagValue
  alias Carrier.TenantRepo

  defmacro __using__([]) do
    quote do
      alias Carrier.Setting.{Property, FeatureFlag, FeatureFlagValue}
    end
  end

  @decorate cacheable(
              cache: Cache.Local,
              key:
                {__MODULE__, :get_feature_flag_value, [feature_flag_key, TenantRepo.get_org_id()]}
            )
  def get_feature_flag_value(feature_flag_key) do
    FeatureFlagValue.get_by_feature_flag_key(feature_flag_key)
    |> TenantRepo.one()
    |> case do
      %FeatureFlagValue{value: value} ->
        value

      nil ->
        # TODO: Generate feature_flag_value with rules

        false
    end
  end
end
