defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo

  def create_conn_info(%{org_id: org_id, name: name, type: type, info: info}) do
    ConnInfo.create(%{org_id: org_id, name: name, type: type, info: info})
    |> TenantRepo.insert()
  end
end
