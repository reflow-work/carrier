defmodule Carrier.TenantRepo do
  @moduledoc """
  https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html#adding-org_id-to-read-operations
  """

  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres

  use Doumi.RepoHelper
  use Carrier.Pagex

  require Ecto.Query

  @impl true
  def prepare_query(_operation, query, opts) do
    query =
      cond do
        opts[:oban] -> query
        opts[:skip_org_id] -> query
        opts[:org_id] == :skip -> query
        is_integer(opts[:org_id]) -> Ecto.Query.where(query, org_id: ^opts[:org_id])
        true -> raise "expected org_id to be set"
      end

    {query, opts}
  end

  @impl true
  def default_options(_operation) do
    [org_id: get_org_id()]
  end

  def put_org_id(org_id) do
    Process.put(tenant_key(), org_id)
  end

  def get_org_id() do
    Process.get(tenant_key())
  end

  def set_skip_org_id() do
    Process.put(tenant_key(), :skip)
  end

  def tenant_key() do
    {__MODULE__, :org_id}
  end
end
