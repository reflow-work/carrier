defmodule Carrier.Data.QueryData do
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo

  def query(%{org_id: org_id, conn_info_id: conn_info_id, sql: sql}) do
    TenantRepo.put_org_id(org_id)

    with {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{header: header, rows: rows}} <- run_query(conn_info, sql) do
      {:ok, %{header: header, rows: rows}}
    end
  end

  defp run_query(%ConnInfo{type: type, info: info}, sql) do
    case type do
      "postgres" ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        %{columns: columns, rows: rows} =
          PostgresRepo.with_dynamic_repo(credentials, fn ->
            PostgresRepo.query!(sql, [])
          end)

        {:ok, %{header: columns, rows: rows}}
    end
  end
end
