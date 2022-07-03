defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnectionInfo
  alias Carrier.Repo

  def create_connection_info(%{org_id: org_id, name: name, type: type, info: info}) do
    ConnectionInfo.create(%{org_id: org_id, name: name, type: type, info: info})
    |> Repo.insert()
  end
end
