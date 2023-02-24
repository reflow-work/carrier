defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnValidator
  alias Carrier.Secrets.{Integration, DataSource, ConnInfo}
  alias Carrier.TenantRepo

  defmacro __using__([]) do
    quote do
      alias Carrier.Secrets
      alias Carrier.Secrets.ConnValidator
      alias Carrier.Secrets.{Integration, DataSource, ConnInfo}
    end
  end

  def create_integration(%{
        org_id: org_id,
        service_name: service_name,
        conn_info: conn_info_params
      }) do
    conn_info_params = %{
      org_id: org_id,
      name: service_name |> Atom.to_string(),
      source: service_name,
      info: conn_info_params
    }

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %ConnInfo{id: conn_info_id}} <- create_conn_info(conn_info_params),
           {:ok, %Integration{} = integration} <-
             Integration.create(%{
               org_id: org_id,
               service_name: service_name,
               conn_info_id: conn_info_id
             })
             |> TenantRepo.insert() do
        {:ok, integration}
      end
    end)
  end

  def create_data_source(%{
        org_id: org_id,
        name: name,
        source: source,
        conn_info: conn_info_params
      }) do
    conn_info_params = %{
      org_id: org_id,
      name: name,
      source: source,
      info: conn_info_params
    }

    TenantRepo.wrap_transaction(fn ->
      with {:ok, %ConnInfo{id: conn_info_id}} <-
             create_conn_info(conn_info_params) |> IO.inspect(label: "conn"),
           {:ok, %DataSource{} = data_source} <-
             DataSource.create(%{
               org_id: org_id,
               name: name,
               source: source,
               conn_info_id: conn_info_id
             })
             |> TenantRepo.insert() do
        {:ok, data_source}
      end
    end)
  end

  def list_integrations() do
    Integration.list()
    |> DataSource.preload_conn_info()
    |> TenantRepo.all()
  end

  def fetch_integration(integration_id) do
    Integration.fetch(integration_id)
    |> DataSource.preload_conn_info()
    |> TenantRepo.one()
    |> case do
      %Integration{} = integration ->
        {:ok, integration}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: Integration, conditions: %{integration_id: integration_id}}}}
    end
  end

  def list_data_sources() do
    DataSource.list()
    |> DataSource.preload_conn_info()
    |> TenantRepo.all()
  end

  def fetch_data_source(data_source_id) do
    DataSource.fetch(data_source_id)
    |> DataSource.preload_conn_info()
    |> TenantRepo.one()
    |> case do
      %DataSource{} = data_source ->
        {:ok, data_source}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: DataSource, conditions: %{data_source_id: data_source_id}}}}
    end
  end

  def create_conn_info(%{org_id: org_id, name: name, source: source, info: info}) do
    with :ok <- ConnValidator.validate(source, info),
         {:ok, %ConnInfo{} = conn_info} <-
           ConnInfo.create(%{org_id: org_id, name: name, source: source, info: info})
           |> TenantRepo.insert() do
      {:ok, conn_info}
    end
  end

  def list_conn_infos() do
    ConnInfo.list()
    |> TenantRepo.all()
  end
end
