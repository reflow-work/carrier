defmodule Carrier.SecretsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Secrets
  alias Carrier.Secrets.{Integration, DataSource, ConnInfo}

  @moduletag repo: TenantRepo

  describe "create_integration/1" do
    setup do
      org = TenantFactory.insert(:org)

      valid_params = %{
        org_id: org.org_id,
        service_name: :slack,
        conn_info: %{
          team_name: "dongrami",
          team_id: "T03LL747Q49",
          bot_token: "bot_token"
        }
      }

      %{valid_params: valid_params}
    end

    test "with valid params", %{valid_params: valid_params} do
      assert {:ok, %Integration{} = integration} = Secrets.create_integration(valid_params)

      assert same_fields?(integration, valid_params, [:org_id, :service_name])
    end
  end

  describe "create_data_source/1" do
    setup do
      org = TenantFactory.insert(:org)

      valid_params = %{
        org_id: org.org_id,
        name: "my app database",
        source: :postgres,
        conn_info: %{
          hostname: "localhost",
          port: 48140,
          username: "postgres",
          password: "postgres",
          database: "postgres"
        }
      }

      %{valid_params: valid_params}
    end

    test "with valid params", %{valid_params: valid_params} do
      assert {:ok, %DataSource{} = data_source} = Secrets.create_data_source(valid_params)

      assert same_fields?(data_source, valid_params, [:org_id, :name, :source])
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

  describe "list_integrations/0" do
    setup do
      org = TenantFactory.insert(:org)

      integration = TenantFactory.insert(:integration, org_id: org.org_id)
      TenantFactory.insert(:integration, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(integration.org_id)

      %{integration: integration}
    end

    test "with valid params", %{integration: integration} do
      assert [fetched_integration] = Secrets.list_integrations()
      assert same_records?(fetched_integration, integration)
    end
  end

  describe "fetch_integration/1" do
    setup do
      org = TenantFactory.insert(:org)

      integration = TenantFactory.insert(:integration, org_id: org.org_id)

      deleted_integration =
        TenantFactory.insert(:integration, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(integration.org_id)

      %{integration: integration, deleted_integration: deleted_integration}
    end

    test "with valid id", %{integration: integration} do
      assert {:ok, fetched_integration} = Secrets.fetch_integration(integration.id)
      assert same_records?(fetched_integration, integration)
      assert %ConnInfo{} = fetched_integration.conn_info
    end

    test "with deleted id", %{deleted_integration: deleted_integration} do
      assert {:error, {:resource_not_found, _}} =
               Secrets.fetch_integration(deleted_integration.id)
    end
  end

  describe "list_data_source/0" do
    setup do
      org = TenantFactory.insert(:org)
      data_source = TenantFactory.insert(:data_source, org_id: org.org_id)
      TenantFactory.insert(:data_source, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(data_source.org_id)

      %{data_source: data_source}
    end

    test "with valid params", %{data_source: data_source} do
      assert [%DataSource{} = fetched_data_source0] = Secrets.list_data_sources()

      assert same_records?(fetched_data_source0, data_source)
      assert %ConnInfo{} = fetched_data_source0.conn_info
    end
  end

  describe "fetch_data_source/1" do
    setup do
      org = TenantFactory.insert(:org)
      data_source = TenantFactory.insert(:data_source)

      deleted_data_source =
        TenantFactory.insert(:data_source, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(data_source.org_id)

      %{data_source: data_source, deleted_data_source: deleted_data_source}
    end

    test "with valid id", %{data_source: data_source} do
      assert {:ok, %DataSource{} = fetched_data_source} =
               Secrets.fetch_data_source(data_source.id)

      assert same_records?(fetched_data_source, data_source)
      assert %ConnInfo{} = fetched_data_source.conn_info
    end

    test "with deleted id", %{deleted_data_source: deleted_data_source} do
      assert {:error, {:resource_not_found, _}} =
               Secrets.fetch_data_source(deleted_data_source.id)
    end
  end
end
