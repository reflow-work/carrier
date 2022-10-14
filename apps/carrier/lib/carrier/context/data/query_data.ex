defmodule Carrier.Data.QueryData do
  require Logger
  alias Carrier.Secrets
  alias Carrier.Secrets.{DataSource, ConnInfo}
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.{PostgresRepo, MySQLRepo}
  alias Carrier.Core.DataHelper

  @start_template "{{start}}"
  @end_template "{{end}}"

  # def query_sample(%{
  #       org_id: org_id,
  #       data_source_id: data_source_id,
  #       sql_template: sql_template,
  #       datetime: datetime,
  #       timezone: timezone,
  #       period: period,
  #       limit: limit
  #     }) do
  #   TenantRepo.put_org_id(org_id)

  #   end_datetime = datetime |> DateTime.shift_zone!(timezone) |> Timex.beginning_of_day()
  #   data_start_datetime = end_datetime |> Timex.shift(days: -(period - 1))

  #   sql_params = [data_start_datetime, end_datetime, limit]

  #   with :ok <- is_valid_sql?(sql_template),
  #        sql = sql_template |> convert_sql_template_to_sql() |> append_limit(),
  #        {:ok, %DataSource{conn_info: %ConnInfo{} = conn_info}} =
  #          Secrets.fetch_data_source(data_source_id),
  #        {:ok, %{columns: columns, rows: rows}} <-
  #          run_query(conn_info, sql, sql_params),
  #        data = DataHelper.rows_to_map(columns, rows) do
  #     {:ok, %{columns: columns, data: data}}
  #   else
  #     error -> error
  #   end
  # end

  def query(
        %{
          org_id: org_id,
          data_source_id: data_source_id,
          sql_template: sql_template,
          datetime: datetime,
          timezone: timezone,
          period: period,
          window_size: window_size,
          comparing_period: comparing_period
        } = params
      ) do
    TenantRepo.put_org_id(org_id)

    end_datetime =
      datetime
      |> DateTime.shift_zone!(timezone)
      |> Timex.beginning_of_day()
      |> DateTime.shift_zone!("Etc/UTC")

    data_start_datetime =
      end_datetime |> Timex.shift(days: -(period - 1 + window_size + comparing_period))

    sql_params = [data_start_datetime, end_datetime]

    with :ok <- is_valid_sql?(sql_template),
         {:ok, %DataSource{conn_info: %ConnInfo{} = conn_info}} =
           Secrets.fetch_data_source(data_source_id),
         {:ok, %{columns: columns, rows: rows}} <-
           run_query(conn_info, sql_template, sql_params),
         normalized_rows = normalize_rows(rows),
         data = DataHelper.rows_to_map(columns, normalized_rows),
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
      {:error, {:query_error, _message} = reason} ->
        Logger.error(inspect({reason, params}))

        {:error, reason}

      {:error, reason} ->
        Logger.error(inspect({reason, params}))

        {:error, :query_failed}
    end
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :query_failed}
  end

  def refine_data_based_on_columns(%{columns: columns, data: data}, selected_columns) do
    [date_column | value_columns] = columns

    value_columns
    |> Enum.filter(&(&1 in selected_columns))
    |> Enum.map(fn value_column ->
      data_by_column = split_data_by_columns(value_column, date_column, data)
      meta_data = build_meta_data(date_column, value_column, data_by_column)

      {value_column, Enum.into([{:meta, meta_data}, {:data, data_by_column}], %{})}
    end)
    |> Enum.into(%{})
  end

  def format_data_for_preview(raw_data) do
    data =
      raw_data.data
      |> Enum.map(fn d ->
        Enum.reduce(raw_data.columns, [], fn c, acc ->
          [d[c] | acc]
        end)
        |> Enum.reverse()
      end)
      |> Enum.reverse()

    Map.put(raw_data, :data, data)
  end

  defp build_meta_data(date_column_name, key, data) do
    current_period_sum_key = window_sum_column(key)
    previous_period_sum_key = window_sum_offset_column(key)
    current_to_previous_periods_sum_ratio_key = window_sum_over_column(key)

    last_datum =
      data
      |> List.last(data)

    previous_period_last_datum = Enum.at(data, -8)

    diff_between_period_sums_in_percentage =
      last_datum[current_to_previous_periods_sum_ratio_key]
      |> case do
        value when is_number(value) ->
          value
          |> Decimal.from_float()
          |> Decimal.sub(1)
          |> Decimal.round(4)
          |> Decimal.mult(100)
          |> Decimal.to_float()

        value when is_atom(value) ->
          value
      end

    %{
      label: key,
      date_column_name: date_column_name,
      current_period_last_tick_raw: last_datum[key],
      previous_period_last_tick_raw: previous_period_last_datum[key],
      current_period_sum: last_datum[current_period_sum_key],
      previous_period_sum: last_datum[previous_period_sum_key],
      current_to_previous_periods_sum_ratio:
        last_datum[current_to_previous_periods_sum_ratio_key],
      diff_between_period_sums_in_percentage: diff_between_period_sums_in_percentage,
      diff_between_period_raws: last_datum[key] - previous_period_last_datum[key]
    }
  end

  defp split_data_by_columns(key, date_column, data) do
    current_period_sum_key = window_sum_column(key)
    previous_period_sum_key = window_sum_offset_column(key)
    current_to_previous_periods_sum_ratio = window_sum_over_column(key)

    Enum.map(
      data,
      fn datum ->
        %{
          date_column => datum[date_column],
          key => datum[key],
          current_period_sum_key => datum[current_period_sum_key],
          previous_period_sum_key => datum[previous_period_sum_key],
          current_to_previous_periods_sum_ratio => datum[current_to_previous_periods_sum_ratio]
        }
      end
    )
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

    window_sum_mutations = fn df ->
      value_columns
      |> Enum.map(fn column ->
        {window_sum_column(column), Explorer.Series.window_sum(df[column], window_size)}
      end)
    end

    df = df |> Explorer.DataFrame.mutate_with(window_sum_mutations)

    window_sum_offsets =
      value_columns
      |> Enum.map(fn column ->
        {
          window_sum_offset_column(column),
          Explorer.Series.concat(
            Explorer.Series.from_list(List.duplicate(nil, comparing_period)),
            df[window_sum_column(column)]
          )
          |> Explorer.Series.head(height)
        }
      end)

    # https://github.com/elixir-nx/explorer/issues/355

    # window_sum_offset_mutations = fn df ->
    #   value_columns
    #   |> Enum.map(fn column ->
    #     {
    #       window_sum_offset_column(column),
    #       Explorer.Series.concat(
    #         Explorer.Series.from_list(List.duplicate(nil, comparing_period)),
    #         df[window_sum_column(column)]
    #       )
    #       |> Explorer.Series.head(height)
    #     }
    #   end)
    # end

    window_sum_over_mutations = fn df ->
      value_columns
      |> Enum.map(fn column ->
        {
          window_sum_over_column(column),
          Explorer.Series.divide(
            df[window_sum_column(column)],
            df[window_sum_offset_column(column)]
          )
        }
      end)
    end

    data =
      df
      |> Explorer.DataFrame.mutate(window_sum_offsets)
      |> Explorer.DataFrame.mutate_with(window_sum_over_mutations)
      |> Explorer.DataFrame.tail(period)
      |> Explorer.DataFrame.to_rows()

    {:ok, data}
  end

  defp convert_sql_template_to_sql(sql_template, :postgres) do
    sql_template
    |> String.trim_trailing(";")
    |> String.replace(@start_template, "$1::TIMESTAMP")
    |> String.replace(@end_template, "$2::TIMESTAMP")
  end

  defp convert_sql_template_to_sql(sql_template, :mysql) do
    sql_template
    |> String.trim_trailing(";")
    |> String.replace(@start_template, "TIMESTAMP(?)")
    |> String.replace(@end_template, "TIMESTAMP(?)")
  end

  # defp append_limit(sql) do
  #   sql <> " LIMIT $3"
  # end

  defp is_valid_sql?(sql_template) do
    with :ok <- is_select_query?(sql_template),
         :ok <- is_contains_required_templates?(sql_template) do
      :ok
    else
      {:error, reason} -> {:error, reason}
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

  defp run_query(%ConnInfo{source: source, info: info}, sql_template, sql_params) do
    sql = sql_template |> convert_sql_template_to_sql(source)

    case source do
      :postgres ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        %{columns: columns, rows: rows} =
          PostgresRepo.with_dynamic_repo(credentials, fn ->
            PostgresRepo.query!(sql, sql_params)
          end)

        {:ok, %{columns: columns, rows: rows}}

      :mysql ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        %{columns: columns, rows: rows} =
          MySQLRepo.with_dynamic_repo(credentials, fn ->
            MySQLRepo.query!(sql, sql_params)
          end)

        {:ok, %{columns: columns, rows: rows}}
    end
  rescue
    error in Postgrex.Error ->
      %Postgrex.Error{postgres: %{message: message}} = error

      {:error, {:query_error, message}}

    error in MyXQL.Error ->
      %MyXQL.Error{message: message} = error

      {:error, {:query_error, message}}
  end

  defp normalize_rows(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Enum.map(fn
        %Decimal{} = value -> Decimal.to_float(value)
        value -> value
      end)
    end)
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
    |> Enum.sort_by(fn %{^date_column => date} -> date end, {:asc, Date})
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
