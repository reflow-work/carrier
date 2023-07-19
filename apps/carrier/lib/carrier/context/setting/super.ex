defmodule Carrier.Setting.Super do
  use Carrier.Setting
  use Carrier.Core.Cache
  require Logger
  alias Carrier.TenantRepo

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_property_value, [key, default_value]},
              opts: [ttl: Cache.ttl(:timer.seconds(10))]
            )
  def get_property_value(key, default_value) do
    case get_property(key) do
      %Property{value: value} = property when not is_nil(value) ->
        Property.get_value_by_type(property)

      _ ->
        Logger.warning("property not found for key: #{key}")
        default_value
    end
  end

  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_feature_flag, [key]},
              opts: [ttl: Cache.ttl(:infinity)]
            )
  def get_feature_flag(key) do
    FeatureFlag.get_by_key(key)
    |> TenantRepo.one(org_id: :skip)
  end

  defp get_property(key) do
    Property.get(key)
    |> TenantRepo.one(org_id: :skip)
  end
end
