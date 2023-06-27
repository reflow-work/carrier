defmodule Carrier.IntegrationsTest do
  use Carrier.DataCase, async: true
  alias Carrier.Integrations
  alias Carrier.Integrations.{DataTarget, DataSource, ConnInfo}
  alias Carrier.ExternalHelper

  @moduletag repo: TenantRepo

  describe "create_data_target/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      valid_params = %{
        org_id: org.org_id,
        service_name: :slack,
        conn_info: %{
          bot_token: "bot_token",
          bot_scope: "chat:write,channels:read",
          team_name: "dongrami",
          team_id: "T03LL747Q49"
        }
      }

      %{valid_params: valid_params}
    end

    test "with valid params", %{valid_params: valid_params} do
      ExternalHelper.SlackAPI.prepare_api_test()

      assert {:ok, %DataTarget{} = data_target} = Integrations.create_data_target(valid_params)

      assert same_fields?(data_target, valid_params, [:org_id, :service_name])
    end
  end

  describe "create_data_source/1" do
    setup do
      org = TenantFactory.insert(:org)
      TenantRepo.put_org_id(org.org_id)

      params = %{
        org_id: org.org_id,
        name: "my data source",
        source: nil,
        conn_info: nil
      }

      %{params: params}
    end

    test "with valid params (postgres)", %{params: params} do
      conn_info = %{
        hostname: "localhost",
        port: 48140,
        username: "postgres",
        password: "postgres",
        database: "postgres"
      }

      params = %{params | source: :postgres, conn_info: conn_info}

      assert {:ok, %DataSource{} = data_source} = Integrations.create_data_source(params)

      assert same_fields?(data_source, params, [:org_id, :name, :source])
    end

    test "with valid params (tableau user)", %{params: params} do
      ExternalHelper.TableauAPI.prepare_signin()

      conn_info = %{
        host: "http://localhost:4102",
        site: "reflow",
        type: :user,
        email: "tableau@reflow.work",
        password: "password"
      }

      params = %{params | source: :tableau, conn_info: conn_info}

      assert {:ok, %DataSource{} = data_source} = Integrations.create_data_source(params)

      assert same_fields?(data_source, params, [:org_id, :name, :source])
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
      assert {:ok, %ConnInfo{} = created_conn_info} =
               Integrations.create_conn_info(valid_params, :source)

      assert same_fields?(created_conn_info, valid_params, [:org_id, :name, :source, :info])
    end

    test "with not unique {org_id, name}", %{org: org, valid_params: valid_params} do
      TenantFactory.insert(:conn_info, org_id: org.org_id, name: valid_params.name)

      assert_changeset_error(:name, "has already been taken", fn ->
        Integrations.create_conn_info(valid_params, :source)
      end)
    end

    test "with invalid info", %{valid_params: valid_params} do
      invalid_params = valid_params |> put_in([:info, :database], "invalid_database")

      assert {:error, :invalid_conn_info} = Integrations.create_conn_info(invalid_params, :source)
    end
  end

  describe "update_conn_info_of_data_target/2" do
    setup do
      org = TenantFactory.insert(:org)

      TenantRepo.put_org_id(org.org_id)

      data_target = TenantFactory.insert(:data_target, org_id: org.org_id, needs_update: true)

      %{data_target: data_target}
    end

    test "with valid params", %{data_target: data_target} do
      params = %{
        info: %{
          bot_token: "bot_token",
          bot_scope: "chat:write,channels:read",
          team_name: "dongrami",
          team_id: "T03LL747Q49"
        }
      }

      assert {:ok, %DataTarget{} = updated_data_target} =
               Integrations.update_conn_info_of_data_target(data_target.id, params)

      assert updated_data_target.needs_update == false
      assert updated_data_target.conn_info.info == params.info
    end
  end

  describe "list_data_targets/0" do
    setup do
      org = TenantFactory.insert(:org)

      data_target = TenantFactory.insert(:data_target, org_id: org.org_id)
      TenantFactory.insert(:data_target, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(data_target.org_id)

      %{data_target: data_target}
    end

    test "with valid params", %{data_target: data_target} do
      assert {:ok, [fetched_data_target]} = Integrations.list_data_targets()
      assert same_records?(fetched_data_target, data_target)
    end
  end

  describe "fetch_data_target/1" do
    setup do
      org = TenantFactory.insert(:org)

      data_target = TenantFactory.insert(:data_target, org_id: org.org_id)

      deleted_data_target =
        TenantFactory.insert(:data_target, org_id: org.org_id, deleted_at: DateTime.utc_now())

      TenantRepo.put_org_id(data_target.org_id)

      %{data_target: data_target, deleted_data_target: deleted_data_target}
    end

    test "with valid id", %{data_target: data_target} do
      assert {:ok, fetched_data_target} = Integrations.fetch_data_target(data_target.id)
      assert same_records?(fetched_data_target, data_target)
      assert %ConnInfo{} = fetched_data_target.conn_info
    end

    test "with deleted id", %{deleted_data_target: deleted_data_target} do
      assert {:error, {:resource_not_found, _}} =
               Integrations.fetch_data_target(deleted_data_target.id)
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
      assert {:ok, [%DataSource{} = fetched_data_source0 | _]} = Integrations.list_data_sources()

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
               Integrations.fetch_data_source(data_source.id)

      assert same_records?(fetched_data_source, data_source)
      assert %ConnInfo{} = fetched_data_source.conn_info
    end

    test "with deleted id", %{deleted_data_source: deleted_data_source} do
      assert {:error, {:resource_not_found, _}} =
               Integrations.fetch_data_source(deleted_data_source.id)
    end
  end
end
