defmodule Carrier.Setting.Super do
  use Carrier.Setting
  use Carrier.Core.Cache
  require Logger
  alias Carrier.Repo

  @ttl :timer.seconds(10)
  @decorate cacheable(
              cache: Cache.Local,
              key: {__MODULE__, :get_property_value, [key, default_value]},
              opts: [ttl: @ttl]
            )
  def get_property_value(key, default_value) do
    case get_property(key) do
      %Property{value: value} when not is_nil(value) ->
        value

      _ ->
        Logger.warn("property not found for key: #{key}")
        default_value
    end
  end

  @decorate cacheable(cache: Cache.Local, key: {__MODULE__, :get_feature_flag, [key]})
  def get_feature_flag(key) do
    FeatureFlag.get_by_key(key)
    |> Repo.one()
  end

  defp get_property(key) do
    Property.get(key)
    |> Repo.one()
  end
end
