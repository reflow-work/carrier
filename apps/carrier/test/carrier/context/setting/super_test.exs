defmodule Carrier.Setting.SuperTest do
  use Carrier.DataCase, async: true
  alias Carrier.Setting

  @moduletag repo: TenantRepo

  describe "get_property_value/2" do
    test "returns the value of the property with valid params" do
      property = TenantFactory.insert(:property, type: :integer, value: 1)

      assert Setting.Super.get_property_value(property.key, 0) == 1
    end

    test "returns default value with invalid key" do
      _property = TenantFactory.insert(:property, type: :integer, value: 1)

      assert Setting.Super.get_property_value("invalid_key", 0) == 0
    end

    test "returns default value with nil value" do
      property = TenantFactory.insert(:property, type: :integer, value: nil)

      assert Setting.Super.get_property_value(property.key, 0) == 0
    end

    test "with integer value" do
      property = TenantFactory.insert(:property, type: :integer, value: 1)

      assert Setting.Super.get_property_value(property.key, 0) == 1
    end

    test "with float value" do
      property = TenantFactory.insert(:property, type: :float, value: 1.1)

      assert Setting.Super.get_property_value(property.key, 0.0) == 1.1
    end

    test "with string value" do
      property = TenantFactory.insert(:property, type: :string, value: "string")

      assert Setting.Super.get_property_value(property.key, "default") == "string"
    end

    test "with boolean value" do
      property = TenantFactory.insert(:property, type: :boolean, value: true)

      assert Setting.Super.get_property_value(property.key, false) == true
    end

    test "with list value" do
      property = TenantFactory.insert(:property, type: :list, value: [1, 2, 3])

      assert Setting.Super.get_property_value(property.key, []) == [1, 2, 3]
    end

    test "with map value" do
      property = TenantFactory.insert(:property, type: :map, value: %{"a" => 1, "b" => 2})

      assert Setting.Super.get_property_value(property.key, %{}) == %{"a" => 1, "b" => 2}
    end

    test "with datetime value" do
      property = TenantFactory.insert(:property, type: :datetime, value: ~U[2023-04-18 09:00:00Z])

      assert Setting.Super.get_property_value(property.key, ~U[2023-07-26 15:00:00Z]) ==
               ~U[2023-04-18 09:00:00Z]
    end
  end

  describe "get_feature_flag/1" do
    setup do
      feature_flag = TenantFactory.insert(:feature_flag)

      %{feature_flag: feature_flag}
    end

    test "with valid key", %{feature_flag: feature_flag} do
      assert Setting.Super.get_feature_flag(feature_flag.key) == feature_flag
    end

    test "with invalid key" do
      assert Setting.Super.get_feature_flag("invalid key") == nil
    end
  end
end
