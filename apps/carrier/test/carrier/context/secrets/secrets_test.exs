defmodule Carrier.SecretsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo

  describe "create_conn_info/1" do
    setup do
      org = insert(:org)

      %{org: org}
    end

    test "with valid params", %{org: org} do
      params = %{
        org_id: org.org_id,
        name: "main",
        type: "postgres",
        info: %{
          "hostname" => "localhost",
          "port" => 5432,
          "username" => "username0",
          "password" => "password0",
          "database" => "database0"
        }
      }

      assert {:ok, %ConnInfo{} = created_conn_info} = Secrets.create_conn_info(params)

      assert same_fields?(created_conn_info, params, [:org_id, :name, :type, :info])
    end
  end
end
