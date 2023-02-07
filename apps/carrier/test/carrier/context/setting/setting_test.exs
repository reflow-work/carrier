defmodule Carrier.SettingTest do
  use Carrier.DataCase, async: true
  alias Carrier.Setting

  @moduletag repo: Repo

  describe "get_property_value/3" do
    setup do
      property = Factory.insert(:property, type: :integer, integer_value: 1)

      {:ok, %{property: property}}
    end

    test "returns the value of the property with valid params", %{property: property} do
      assert 1 = Setting.get_property_value(property.key, property.type, 2)
    end

    test "returns default value with invalid key" do
      assert 2 = Setting.get_property_value("invalid_key", :integer, 2)
    end

    test "returns default value with invalid type", %{property: property} do
      assert 2 = Setting.get_property_value(property.key, :string, 2)
    end

    test "returns default value with nil value" do
      property = Factory.insert(:property, type: :integer, integer_value: nil)

      assert 2 = Setting.get_property_value(property.key, :string, 2)
    end
  end
end
