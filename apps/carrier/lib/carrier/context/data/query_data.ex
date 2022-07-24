defmodule Carrier.Data.QueryData do
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo
  alias Carrier.Core.DataHelper

  # Assumptions
  # - results are ordered by date

  def query_sample(%{
        org_id: org_id,
        conn_info_id: conn_info_id,
        sql_template: sql_template,
        datetime: datetime,
        timezone: timezone,
        period: period,
        limit: limit
      }) do
    TenantRepo.put_org_id(org_id)

    end_datetime = datetime |> DateTime.shift_zone!(timezone) |> Timex.beginning_of_day()
    data_start_datetime = end_datetime |> Timex.shift(days: -(period - 1))

    sql_params = [data_start_datetime, end_datetime, limit]

    with :ok <- is_valid_sql?(sql_template),
         sql = sql_template |> change_sql_template_to_sql() |> append_limit(),
         {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{columns: columns, rows: rows}} <-
           run_query(conn_info, sql, sql_params),
         data = DataHelper.rows_to_map(columns, rows) do
      {:ok, %{columns: columns, data: data}}
    else
      error -> error
    end
  end

  def query(%{
        org_id: org_id,
        conn_info_id: conn_info_id,
        sql_template: sql_template,
        datetime: datetime,
        timezone: timezone,
        period: period,
        window_size: window_size,
        comparing_period: comparing_period
      }) do
    TenantRepo.put_org_id(org_id)

    end_datetime = datetime |> DateTime.shift_zone!(timezone) |> Timex.beginning_of_day()

    data_start_datetime =
      end_datetime |> Timex.shift(days: -(period - 1 + window_size + comparing_period))

    sql_params = [data_start_datetime, end_datetime]

    with :ok <- is_valid_sql?(sql_template),
         sql = sql_template |> change_sql_template_to_sql(),
         {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{columns: columns, rows: rows}} <-
           run_query(conn_info, sql, sql_params),
         data = DataHelper.rows_to_map(columns, rows),
         {:ok, analyzed_date} <-
           data
           |> analyze(%{
             columns: columns,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period
           }) do
      {:ok, %{columns: columns, data: analyzed_date}}
    else
      error -> error
    end
  end

  defp analyze(data, %{
         columns: columns,
         period: period,
         window_size: window_size,
         comparing_period: comparing_period
       }) do
    [_date_column | value_columns] = columns

    df = data |> Explorer.DataFrame.new()
    {height, _width} = df |> Explorer.DataFrame.shape()

    window_sum_mutations =
      value_columns
      |> Enum.map(fn column ->
        {window_sum_column(column), &Explorer.Series.window_sum(&1[column], window_size)}
      end)

    window_sum_offset_mutations =
      value_columns
      |> Enum.map(fn column ->
        {window_sum_offset_column(column),
         fn df ->
           Explorer.Series.concat(
             Explorer.Series.from_list(List.duplicate(nil, comparing_period)),
             df[window_sum_column(column)]
           )
           |> Explorer.Series.head(height)
         end}
      end)

    window_sum_over_mutations =
      value_columns
      |> Enum.map(fn column ->
        {window_sum_over_column(column),
         &Explorer.Series.divide(
           &1[window_sum_column(column)],
           &1[window_sum_offset_column(column)]
         )}
      end)

    data =
      df
      |> Explorer.DataFrame.mutate(window_sum_mutations)
      |> Explorer.DataFrame.mutate(window_sum_offset_mutations)
      |> Explorer.DataFrame.mutate(window_sum_over_mutations)
      |> Explorer.DataFrame.tail(period)
      |> Explorer.DataFrame.to_rows()

    {:ok, data}
  end

  defp change_sql_template_to_sql(sql_template) do
    sql_template
    |> String.replace("{{start_datetime}}", "$1::TIMESTAMP")
    |> String.replace("{{end_datetime}}", "$2::TIMESTAMP")
  end

  defp append_limit(sql) do
    sql <> " LIMIT $3"
  end

  defp is_valid_sql?(sql_template) do
    with true <- Regex.match?(~r/^\s*select\s*/i, sql_template) do
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

  defp window_sum_column(column) do
    column <> "_window_sum"
  end

  defp window_sum_offset_column(column) do
    column <> "_window_sum_offset"
  end

  defp window_sum_over_column(column) do
    column <> "_window_sum_over"
  end
end
