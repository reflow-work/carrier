defmodule Carrier.Tenant do
  def put_org_id(org_id) do
    Process.put(tenant_key(), org_id)
  end

  def get_org_id() do
    Process.get(tenant_key())
  end

  def tenant_key() do
    {__MODULE__, :org_id}
  end
end
