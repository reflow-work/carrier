defmodule Carrier.Setting do
  use Carrier.Core.Cache
  require Logger
  alias Carrier.Setting.Super
  alias Carrier.Setting.{FeatureFlag, FeatureFlagValue}
  alias Carrier.TenantRepo
  alias Carrier.Tenant

  defmacro __using__([]) do
    quote do
      alias Carrier.Setting
      alias Carrier.Setting.{Property, FeatureFlag, FeatureFlagValue}
    end
  end

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_feature_flag_value, [feature_flag_key, Tenant.get_org_id()]},
              opts: [ttl: Cache.ttl(:infinity)]
            )
  def get_feature_flag_value(feature_flag_key) do
    with {:feature_flag, %FeatureFlag{value: false}} <-
           {:feature_flag, Super.get_feature_flag(feature_flag_key)},
         {:feature_flag_value, nil} <-
           {:feature_flag_value, do_get_feature_flag_value(feature_flag_key)} do
      # TODO: Generate feature_flag_value with rules

      false
    else
      {:feature_flag, nil} -> false
      {:feature_flag, %FeatureFlag{value: true}} -> true
      {:feature_flag_value, %FeatureFlagValue{value: value}} -> value
    end
  end

  defp do_get_feature_flag_value(feature_flag_key) do
    FeatureFlagValue.get_by_feature_flag_key(feature_flag_key)
    |> TenantRepo.one()
  end
end
