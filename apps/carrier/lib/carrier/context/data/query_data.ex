defmodule Carrier.Data.QueryData do
  require Logger
  use Carrier.Secrets
  alias Carrier.Data.Source
  alias Carrier.TenantRepo
  alias Carrier.Core.DataHelper

  @start_template "{{start}}"
  @end_template "{{end}}"

  def query(
        %{
          org_id: org_id,
          data_source_id: data_source_id,
          sql_template: sql_template,
          datetime: utc_datetime,
          period: period,
          window_size: window_size,
          comparing_period: comparing_period
        } = params
      ) do
    TenantRepo.put_org_id(org_id)

    end_date = utc_datetime |> DateTime.to_date()
    start_date = end_date |> Date.add(-period)

    query_start_date = start_date |> Date.add(-(window_size + comparing_period + 1))
    query_end_date = end_date |> Date.add(1)

    sql_params = [query_start_date, query_end_date]

    with :ok <- is_valid_sql?(sql_template),
         {:ok, %DataSource{source: source} = data_source} <-
           Secrets.fetch_data_source(data_source_id),
         sql = sql_template |> convert_sql_template_to_sql(source),
         {:ok, %{columns: columns, rows: rows}} <- run_query(data_source, sql, sql_params),
         :ok <- validate_query_result(columns, rows),
         normalized_rows = normalize_rows(rows),
         data = DataHelper.rows_to_map(columns, normalized_rows),
         filled_data = fill_missing_dates(data, columns, query_start_date, end_date),
         {:ok, analyzed_date} <-
           filled_data
           |> analyze(%{
             columns: columns,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period
           }) do
      {:ok, %{columns: columns, data: analyzed_date}}
    else
      {:error, reason} ->
        Logger.error(inspect({reason, params}))

        {:error, reason}
    end
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :query_failed}
  end

  def refine_data_based_on_columns(%{columns: columns, data: data}, selected_columns, window_size) do
    [date_column | value_columns] = columns

    value_columns
    |> Enum.filter(&(&1 in selected_columns))
    |> Enum.map(fn value_column ->
      data_by_column = split_data_by_columns(value_column, date_column, data)
      meta_data = build_meta_data(date_column, value_column, data_by_column, window_size)

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

  def fetch_table_names(
        %{
          org_id: org_id,
          data_source_id: data_source_id
        } = params
      ) do
    TenantRepo.put_org_id(org_id)

    with {:ok, %DataSource{source: source} = data_source} <-
           Secrets.fetch_data_source(data_source_id),
         source_module = Source.get_module(source),
         tables_query = source_module.tables_query(),
         {:ok, %{columns: columns, rows: rows}} <- run_query(data_source, tables_query) do
      table_names =
        DataHelper.rows_to_map(columns, rows)
        |> Enum.map(&"#{&1[source_module.table_name_field()]}")
        |> Enum.sort()

      {:ok, table_names}
    else
      {:error, reason} ->
        Logger.error(inspect({reason, params}))

        {:error, reason}
    end
  end

  def fetch_columns(
        %{
          org_id: org_id,
          data_source_id: data_source_id,
          table_name: table_name
        } = params
      ) do
    TenantRepo.put_org_id(org_id)

    with {:ok, %DataSource{source: source} = data_source} <-
           Secrets.fetch_data_source(data_source_id),
         source_module = Source.get_module(source),
         columns_query = source_module.columns_query(),
         {:ok, %{columns: columns, rows: rows}} <-
           run_query(data_source, columns_query, [table_name]) do
      %{date_columns: date_columns, other_columns: other_columns} =
        DataHelper.rows_to_map(columns, rows)
        |> Enum.group_by(
          fn row ->
            data_type = row |> Map.get(source_module.data_type_field())

            cond do
              source_module.is_date_type?(data_type) -> :date_columns
              true -> :other_columns
            end
          end,
          & &1[source_module.column_name_field()]
        )
        |> Map.put_new(:date_columns, [])
        |> Map.put_new(:other_columns, [])

      columns = %{
        date_columns: date_columns,
        value_columns: other_columns ++ date_columns
      }

      {:ok, columns}
    else
      {:error, reason} ->
        Logger.error(inspect({reason, params}))

        {:error, reason}
    end
  end

  defp build_meta_data(date_column_name, key, data, window_size) do
    current_period_sum_key = window_sum_column(key)
    previous_period_sum_key = window_sum_offset_column(key)
    current_to_previous_periods_sum_ratio_key = window_sum_over_column(key)

    last_datum =
      data
      |> List.last(data)

    previous_period_last_datum = Enum.at(data, -8)

    diff_between_period_raws = last_datum[key] - previous_period_last_datum[key]

    diff_between_period_raws_in_percentage =
      if previous_period_last_datum[key] == 0 do
        :nan
      else
        (diff_between_period_raws / previous_period_last_datum[key])
        |> Decimal.from_float()
        |> Decimal.round(4)
        |> Decimal.mult(100)
        |> Decimal.to_float()
      end

    # FIXME: All window_size == 1 handling is temporary and bad and should be removed

    {previous_period_sum, current_period_sum} =
      if window_size == 1 do
        {previous_period_data, current_period_data} =
          data
          |> Enum.take(-14)
          |> Enum.map(fn d -> d[key] end)
          |> Enum.split(7)

        previous_period_sum = Enum.sum(previous_period_data)
        current_period_sum = Enum.sum(current_period_data)
        {previous_period_sum, current_period_sum}
      else
        {normalize_zero(last_datum[previous_period_sum_key]),
         normalize_zero(last_datum[current_period_sum_key])}
      end

    diff_between_period_sums = current_period_sum - previous_period_sum

    diff_between_period_sums_in_percentage =
      if previous_period_sum == 0 do
        :nan
      else
        if window_size == 1 do
          (diff_between_period_sums / previous_period_sum)
          |> Decimal.from_float()
          |> Decimal.round(4)
          |> Decimal.mult(100)
          |> Decimal.to_float()
        else
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
        end
      end

    %{
      label: key,
      date_column_name: date_column_name,
      window_size: window_size,
      current_period_last_tick_raw: last_datum[key],
      previous_period_last_tick_raw: previous_period_last_datum[key],
      current_period_sum: current_period_sum,
      previous_period_sum: previous_period_sum,
      current_to_previous_periods_sum_ratio:
        last_datum[current_to_previous_periods_sum_ratio_key],
      diff_between_period_raws: diff_between_period_raws,
      diff_between_period_sums: diff_between_period_sums,
      diff_between_period_raws_in_percentage: diff_between_period_raws_in_percentage,
      diff_between_period_sums_in_percentage: diff_between_period_sums_in_percentage
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
    |> String.replace(@start_template, "$1::DATE")
    |> String.replace(@end_template, "$2::DATE")
  end

  defp convert_sql_template_to_sql(sql_template, :mysql) do
    sql_template
    |> String.trim_trailing(";")
    |> String.replace(@start_template, "DATE(?)")
    |> String.replace(@end_template, "DATE(?)")
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

  defp run_query(
         %DataSource{source: source, conn_info: %ConnInfo{} = conn_info},
         sql,
         sql_params \\ []
       ) do
    credentials = ConnInfo.to_credentials(conn_info)

    Source.get_module(source).run_query(credentials, sql, sql_params)
  end

  defp validate_query_result(_columns, []), do: :ok

  defp validate_query_result(_columns, [first_row | _]) do
    with :ok <- is_date_type_at_first_column(first_row),
         :ok <- is_number_type_after_first_column(first_row) do
      :ok
    end
  end

  defp is_date_type_at_first_column(row) do
    case row do
      [%Date{} | _] -> :ok
      _ -> {:error, :first_column_is_not_date_type}
    end
  end

  defp is_number_type_after_first_column([_date | values]) do
    values
    |> Enum.all?(fn
      value when is_number(value) -> true
      %Decimal{} -> true
      _ -> false
    end)
    |> case do
      true -> :ok
      false -> {:error, :not_number_type_after_first_column}
    end
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
         %Date{} = start_date,
         %Date{} = end_date
       ) do
    date_range = Date.range(start_date, end_date |> Date.add(-1))

    date_datum_map =
      data
      |> Enum.map(fn datum -> {datum[date_column], datum} end)
      |> Map.new()

    _filled_data =
      date_range
      |> Enum.reduce([], fn date, acc ->
        case Map.get(date_datum_map, date) do
          nil -> [empty_datum(date, date_column, value_columns) | acc]
          datum -> [datum | acc]
        end
      end)
      |> Enum.reverse()
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

  defp normalize_zero(n) when is_number(n) do
    if n == 0 do
      0
    else
      n
    end
  end
end
