defmodule Carrier.Reports.SuperTest do
  use Carrier.DataCase, async: true
  use Carrier.Reports

  @moduletag repo: TenantRepo

  describe "get_report_log_count/0" do
    setup do
      org0 = TenantFactory.insert(:org)
      org1 = TenantFactory.insert(:org)

      TenantFactory.insert(:report_log, org_id: org0.org_id)
      TenantFactory.insert(:report_log, org_id: org1.org_id)

      :ok
    end

    test "returns the number of report logs" do
      assert {:ok, 2} = Reports.Super.get_report_log_count()
    end
  end
end
