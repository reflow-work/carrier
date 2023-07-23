defmodule Carrier.Roles.RoleTest do
  use Carrier.DataCase, async: true
  alias Carrier.Roles.Role

  describe "report_max_count/1" do
    test "with infinity permission" do
      role = Factory.insert(:role, permissions: ["reports.max-count.infinity"])

      actual = role |> Role.report_max_count()

      assert actual == :infinity
    end

    test "with count permission" do
      max_count = Factory.build(:integer)
      role = Factory.insert(:role, permissions: ["reports.max-count.#{max_count}"])

      actual = role |> Role.report_max_count()

      assert actual == max_count
    end

    test "without permission" do
      role = Factory.insert(:role, permissions: [])

      actual = role |> Role.report_max_count()

      assert actual == 0
    end
  end

  describe "data_source_max_count/1" do
    test "with infinity permission" do
      role = Factory.insert(:role, permissions: ["data-source.max-count.infinity"])

      actual = role |> Role.data_source_max_count()

      assert actual == :infinity
    end

    test "with count permission" do
      max_count = Factory.build(:integer)
      role = Factory.insert(:role, permissions: ["data-source.max-count.#{max_count}"])

      actual = role |> Role.data_source_max_count()

      assert actual == max_count
    end

    test "without permission" do
      role = Factory.insert(:role, permissions: [])

      actual = role |> Role.data_source_max_count()

      assert actual == 0
    end
  end
end
