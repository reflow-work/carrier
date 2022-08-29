defmodule Carrier.Data.QueryData do
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo
  alias Carrier.Core.DataHelper

  @start_template "{{start}}"
  @end_template "{{end}}"

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
         sql = sql_template |> convert_sql_template_to_sql() |> append_limit(),
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
         sql = sql_template |> convert_sql_template_to_sql(),
         {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{columns: columns, rows: rows}} <-
           run_query(conn_info, sql, sql_params),
         data = DataHelper.rows_to_map(columns, rows),
         data = fill_missing_dates(data, columns, data_start_datetime, end_datetime),
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

  defp convert_sql_template_to_sql(sql_template) do
    sql_template
    |> String.trim_trailing(";")
    |> String.replace(@start_template, "$1::TIMESTAMP")
    |> String.replace(@end_template, "$2::TIMESTAMP")
  end

  defp append_limit(sql) do
    sql <> " LIMIT $3"
  end

  defp is_valid_sql?(sql_template) do
    with :ok <- is_select_query?(sql_template),
         :ok <- is_contains_required_templates?(sql_template) do
      :ok
    else
      error -> error
    end
  end

  defp is_select_query?(sql_template) do
    case Regex.match?(~r/^\s*select\s*/i, sql_template) do
      true -> :ok
      false -> {:error, :sql_not_a_select_query}
    end
  end

  defp is_contains_required_templates?(sql_template) do
    case sql_template |> String.contains?([@start_template, @end_template]) do
      true -> :ok
      false -> {:error, :sql_missing_template_keys}
    end
  end

  defp run_query(%ConnInfo{source: source, info: info}, sql, sql_params) do
    case source do
      :postgres ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()
          |> IO.inspect()

        IO.inspect(sql)

        %{columns: columns, rows: rows} =
          PostgresRepo.with_dynamic_repo(credentials, fn ->
            PostgresRepo.query!(sql, sql_params)
          end)

        {:ok, %{columns: columns, rows: rows}}
    end
  rescue
    error in Postgrex.Error ->
      %Postgrex.Error{postgres: %{code: code, message: message, hint: hint}} = error

      {:error, [code, message, hint] |> Enum.join("\n")}
  end

  defp fill_missing_dates(
         data,
         [date_column | value_columns],
         %DateTime{} = start_datetime,
         %DateTime{} = end_datetime
       ) do
    start_date = start_datetime |> DateTime.to_date()
    end_date = end_datetime |> DateTime.to_date()

    date_range = Date.range(start_date, end_date |> Date.add(-1))

    date_datum_map =
      data
      |> Enum.map(fn datum -> {datum[date_column], datum} end)
      |> Map.new()

    filled_date_datum_map =
      date_range
      |> Enum.reduce(date_datum_map, fn date, date_datum_map ->
        case Map.has_key?(date_datum_map, date) do
          true ->
            date_datum_map

          false ->
            empty_data = empty_datum(date, date_column, value_columns)

            date_datum_map |> Map.put(date, empty_data)
        end
      end)

    filled_date_datum_map
    |> Map.values()
    |> Enum.sort_by(fn %{"date" => date} -> date end, {:asc, Date})
  end

  defp empty_datum(%Date{} = date, date_column, value_columns) do
    value_columns
    |> Enum.reduce(%{date_column => date}, fn value_column, datum ->
      datum |> Map.put(value_column, 0)
    end)
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
