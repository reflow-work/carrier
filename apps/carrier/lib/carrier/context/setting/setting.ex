defmodule Carrier.Setting do
  require Logger
  alias Carrier.Setting.Property
  alias Carrier.Repo

  def get_property_value(key, type, default_value) do
    with %Property{type: ^type} = property <- get_property(key),
         value when not is_nil(value) <- Property.get_typed_value(property) do
      value
    else
      _ ->
        Logger.warn("property not found for key: #{key}")
        default_value
    end
  end

  defp get_property(key) do
    Property.get(key)
    |> Repo.one()
  end
end
