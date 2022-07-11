defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo

  def create_conn_info(%{org_id: org_id, name: name, type: type, info: info}) do
    ConnInfo.create(%{org_id: org_id, name: name, type: type, info: info})
    |> TenantRepo.insert()
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
