defmodule Carrier.SettingTest do
  use Carrier.DataCase, async: true
  alias Carrier.Setting

  @moduletag repo: Repo

  describe "get_property_value/2" do
    test "returns the value of the property with valid params" do
      property = Factory.insert(:property, type: :integer, value: 1)

      assert Setting.get_property_value(property.key, 0) == 1
    end

    test "returns default value with invalid key" do
      _property = Factory.insert(:property, type: :integer, value: 1)

      assert Setting.get_property_value("invalid_key", 0) == 0
    end

    test "returns default value with nil value" do
      property = Factory.insert(:property, type: :integer, value: nil)

      assert Setting.get_property_value(property.key, 0) == 0
    end

    test "with integer value" do
      property = Factory.insert(:property, type: :integer, value: 1)

      assert Setting.get_property_value(property.key, 0) == 1
    end

    test "with float value" do
      property = Factory.insert(:property, type: :float, value: 1.1)

      assert Setting.get_property_value(property.key, 0.0) == 1.1
    end

    test "with string value" do
      property = Factory.insert(:property, type: :string, value: "string")

      assert Setting.get_property_value(property.key, "default") == "string"
    end

    test "with boolean value" do
      property = Factory.insert(:property, type: :boolean, value: true)

      assert Setting.get_property_value(property.key, false) == true
    end

    test "with list value" do
      property = Factory.insert(:property, type: :list, value: [1, 2, 3])

      assert Setting.get_property_value(property.key, []) == [1, 2, 3]
    end

    test "with map value" do
      property = Factory.insert(:property, type: :map, value: %{"a" => 1, "b" => 2})

      assert Setting.get_property_value(property.key, %{}) == %{"a" => 1, "b" => 2}
    end
  end
end
