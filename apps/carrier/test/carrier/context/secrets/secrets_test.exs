defmodule Carrier.SecretsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Secrets
  alias Carrier.Secrets.{Integration, ConnInfo}

  @moduletag repo: TenantRepo

  describe "create_integration/1" do
    setup do
      org = TenantFactory.insert(:org)

      valid_params = %{
        org_id: org.org_id,
        service_name: :slack,
        conn_info: %{
          "team_name" => "dongrami",
          "team_id" => "T03LL747Q49"
        }
      }

      %{valid_params: valid_params}
    end

    test "with valid params", %{valid_params: valid_params} do
      assert {:ok, %Integration{} = integration} = Secrets.create_integration(valid_params)

      assert same_fields?(integration, valid_params, [:org_id, :service_name])
    end
  end

  describe "create_conn_info/1" do
    setup do
      org = TenantFactory.insert(:org)

      valid_params = %{
        org_id: org.org_id,
        name: "main",
        source: :postgres,
        info: %{
          hostname: "localhost",
          port: 48140,
          username: "postgres",
          password: "postgres",
          database: "postgres"
        }
      }

      %{org: org, valid_params: valid_params}
    end

    test "with valid params", %{valid_params: valid_params} do
      assert {:ok, %ConnInfo{} = created_conn_info} = Secrets.create_conn_info(valid_params)

      assert same_fields?(created_conn_info, valid_params, [:org_id, :name, :source, :info])
    end

    test "with not unique {org_id, name}", %{org: org, valid_params: valid_params} do
      TenantFactory.insert(:conn_info, org_id: org.org_id, name: valid_params.name)

      assert_changeset_error(:name, "has already been taken", fn ->
        Secrets.create_conn_info(valid_params)
      end)
    end

    test "with invalid info", %{valid_params: valid_params} do
      invalid_params = valid_params |> put_in([:info, :database], "invalid_database")

      assert {:error, :invalid_conn_info} = Secrets.create_conn_info(invalid_params)
    end
  end

  describe "fetch_conn_info/1" do
    setup do
      conn_info = TenantFactory.insert(:conn_info)

      TenantRepo.put_org_id(conn_info.org_id)

      %{conn_info: conn_info}
    end

    test "with valid id", %{conn_info: conn_info} do
      assert {:ok, %ConnInfo{} = fetched_conn_info} = Secrets.fetch_conn_info(conn_info.id)

      assert same_records?(fetched_conn_info, conn_info)
    end
  end
end
