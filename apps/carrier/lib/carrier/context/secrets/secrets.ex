defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnValidator
  alias Carrier.Secrets.{Integration, ConnInfo}
  alias Carrier.TenantRepo

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

  def fetch_conn_info(conn_info_id) do
    ConnInfo.fetch(conn_info_id)
    |> TenantRepo.one()
    |> case do
      %ConnInfo{} = conn_info ->
        {:ok, conn_info}

      nil ->
        {:error,
         {:resource_not_found, %{target: "conn_info", conditions: %{conn_info_id: conn_info_id}}}}
    end
  end
end
