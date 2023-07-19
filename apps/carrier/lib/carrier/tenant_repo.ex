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
  alias Carrier.Tenant

  @impl true
  def prepare_query(_operation, query, opts) do
    query =
      cond do
        opts[:oban] -> query
        opts[:org_id] == :skip -> query
        is_integer(opts[:org_id]) -> Ecto.Query.where(query, org_id: ^opts[:org_id])
        true -> raise "expected org_id to be set"
      end

    {query, opts}
  end

  @impl true
  def default_options(_operation) do
    [org_id: Tenant.get_org_id()]
  end
end
