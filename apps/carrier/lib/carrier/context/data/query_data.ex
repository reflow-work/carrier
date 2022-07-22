defmodule Carrier.Data.QueryData do
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo
  alias Carrier.Core.DataHelper

  def query(%{
        org_id: org_id,
        conn_info_id: conn_info_id,
        sql_template: sql_template,
        datetime: datetime,
        timezone: timezone,
        period: period,
        window_size: window_size
      }) do
    TenantRepo.put_org_id(org_id)

    end_datetime = datetime |> DateTime.shift_zone!(timezone) |> Timex.beginning_of_day()
    data_start_datetime = end_datetime |> Timex.shift(days: -(period - 1 + window_size * 2))

    sql =
      sql_template
      |> String.replace("{{start_datetime}}", "$1::TIMESTAMP")
      |> String.replace("{{end_datetime}}", "$2::TIMESTAMP")

    sql_params = [data_start_datetime, end_datetime]

    with :ok <- is_valid_sql?(sql),
         {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{columns: columns, rows: rows}} <- run_query(conn_info, sql, sql_params) do
      data = DataHelper.rows_to_map(columns, rows)

      {:ok, data}
    else
      error -> error
    end
  end

  defp is_valid_sql?(sql_template) do
    with true <- Regex.match?(~r/^select\s/i, sql_template) do
      :ok
    else
      _ -> {:error, :invalid_sql}
    end
  end

  defp run_query(%ConnInfo{type: type, info: info}, sql, sql_params) do
    case type do
      "postgres" ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        %{columns: columns, rows: rows} =
          PostgresRepo.with_dynamic_repo(credentials, fn ->
            PostgresRepo.query!(sql, sql_params)
          end)

        {:ok, %{columns: columns, rows: rows}}
    end
  end
end
