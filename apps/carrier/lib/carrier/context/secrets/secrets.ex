defmodule Carrier.Secrets do
  alias Carrier.Secrets.ConnInfo
  alias Carrier.Repo

  def create_conn_info(%{org_id: org_id, name: name, type: type, info: info}) do
    ConnInfo.create(%{org_id: org_id, name: name, type: type, info: info})
    |> Repo.insert()
  end
end
