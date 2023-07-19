defmodule Carrier.SettingTest do
  use Carrier.DataCase, async: true
  alias Carrier.Setting

  @moduletag repo: TenantRepo

  describe "get_feature_flag_value/1" do
    setup do
      org0 = TenantFactory.insert(:org)
      org1 = TenantFactory.insert(:org)

      feature_flag = TenantFactory.insert(:feature_flag, key: "test")

      feature_flag_value =
        TenantFactory.insert(:feature_flag_value,
          org_id: org0.org_id,
          feature_flag: feature_flag,
          value: true
        )

      TenantFactory.insert(:feature_flag_value,
        org_id: org1.org_id,
        feature_flag: feature_flag,
        value: false
      )

      Tenant.put_org_id(feature_flag_value.org_id)

      %{feature_flag_value: feature_flag_value}
    end

    test "with valid feature_flag_key", %{feature_flag_value: feature_flag_value} do
      assert Setting.get_feature_flag_value(feature_flag_value.feature_flag_key) == true
    end

    test "with invalid feature_flag_key" do
      assert Setting.get_feature_flag_value("invalid_feature_flag_key") == false
    end

    test "with not set org", %{feature_flag_value: feature_flag_value} do
      Tenant.put_org_id(0)

      assert Setting.get_feature_flag_value(feature_flag_value.feature_flag_key) == false
    end
  end
end
