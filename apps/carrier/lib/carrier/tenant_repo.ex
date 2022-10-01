defmodule Carrier.TenantRepo do
  @moduledoc """
  https://hexdocs.pm/ecto/multi-tenancy-with-foreign-keys.html#adding-org_id-to-read-operations
  """

  use Ecto.Repo,
    otp_app: :carrier,
    adapter: Ecto.Adapters.Postgres

  use Doumi.RepoHelper

  require Ecto.Query

  @impl true
  def prepare_query(_operation, query, opts) do
    case opts[:org_id] do
      :skip ->
        {query, opts}

      org_id when is_integer(org_id) ->
        {Ecto.Query.where(query, org_id: ^org_id), opts}

      _ ->
        raise "expected org_id to be set"
    end
  end

  @impl true
  def default_options(_operation) do
    [org_id: get_org_id()]
  end

  @tenant_key {__MODULE__, :org_id}

  def put_org_id(org_id) do
    Process.put(@tenant_key, org_id)
  end

  def get_org_id() do
    Process.get(@tenant_key)
  end

  def set_skip_org_id() do
    Process.put(@tenant_key, :skip)
  end
end
