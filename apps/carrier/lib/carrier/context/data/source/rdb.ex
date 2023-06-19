defmodule Carrier.Data.Source.RDB do
  # required
  @callback validation_query() :: String.t()
  @callback param(n :: integer()) :: String.t()
  @callback run_query(
              credentials :: map(),
              sql :: String.t(),
              sql_params :: list(),
              opts :: keyword()
            ) ::
              {:ok, %{columns: list(), rows: list()}} | {:error, any()}

  # optional
  @callback tables_query() :: String.t()
  @callback table_name_field() :: String.t()
  @callback columns_query() :: String.t()
  @callback column_name_field() :: String.t()
  @callback data_type_field() :: String.t()
  @callback is_date_type?(type :: String.t()) :: boolean()

  @optional_callbacks [
    tables_query: 0,
    table_name_field: 0,
    columns_query: 0,
    column_name_field: 0,
    data_type_field: 0,
    is_date_type?: 1
  ]

  @behaviour Carrier.Data.Source

  use Carrier.Integrations

  @impl true
  def validate_conn(source, credentials, opts) do
    query = get_module(source).validation_query()

    case run_query(source, credentials, query, [], opts) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  @start_template_key "start"
  @end_template_key "end"
  @start_template "{{#{@start_template_key}}}"
  @end_template "{{#{@end_template_key}}}"

  @impl true
  def load_raw_data(
        %{data_source_info: %{params: %{sql_template: sql_template} = params}},
        %DataSource{source: source} = data_source
      ) do
    {query_start_date, query_end_date} = calc_query_start_end_date(params)
    query_params = %{"start" => query_start_date, "end" => query_end_date}

    credentials = DataSource.to_credentials(data_source)

    with :ok <- is_valid_sql?(sql_template),
         {:ok, %{columns: columns, data: data} = query_result} <-
           run_query(source, credentials, sql_template, query_params),
         :ok <- validate_query_result(query_result) do
      data =
        data
        |> normalize_data()
        |> fill_missing_dates(columns, query_start_date, query_end_date)

      {:ok, %{columns: columns, data: data}}
    end
  end

  defp calc_query_start_end_date(%{
         datetime: utc_datetime,
         timezone: timezone,
         period_days: period_days,
         over_days: over_days,
         window_days: window_days
       }) do
    query_end_date =
      utc_datetime
      |> DateTime.shift_zone!(timezone)
      |> DateTime.to_date()

    query_start_date = query_end_date |> Date.add(-(period_days + over_days + window_days + 1))

    {query_start_date, query_end_date}
  end

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

  defp validate_query_result(%{columns: columns, data: [first_datum | _]}) do
    with :ok <- is_temporal_type_at_first_column(columns, first_datum),
         :ok <- is_number_type_after_first_column(columns, first_datum) do
      :ok
    end
  end

  defp validate_query_result(%{data: []}) do
    {:error, :no_data}
  end

  # TODO: change DateTime to :ok
  defp is_temporal_type_at_first_column([first_column | _], datum) do
    case datum |> Map.get(first_column) do
      %Date{} -> :ok
      _ -> {:error, :first_column_is_not_date_type}
    end
  end

  defp is_number_type_after_first_column([_ | rest_columns], datum) do
    rest_columns
    |> Enum.map(&Map.get(datum, &1))
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

  defp normalize_data(data) do
    data
    |> Enum.map(fn datum ->
      datum
      |> Map.new(fn
        {key, %Decimal{} = value} -> {key, Decimal.to_float(value)}
        {key, nil} -> {key, 0}
        pair -> pair
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

  require Logger
  alias Carrier.Core.DataHelper

  def sources() do
    [:postgres, :mysql, :bigquery, :athena]
  end

  def get_module(source) do
    case source do
      :postgres -> __MODULE__.Postgres
      :mysql -> __MODULE__.MySQL
      :bigquery -> __MODULE__.BigQuery
      :athena -> __MODULE__.Athena
    end
  end

  def support_query_maker?(source) do
    source in [:postgres, :mysql]
  end

  def run_query(source, credentials, query, query_params \\ %{}, opts \\ []) do
    source_module = get_module(source)

    with {:ok, {query, sql_params}} <-
           parameterize_query(query, query_params, &source_module.param/1),
         {:ok, %{columns: columns, rows: rows}} <-
           source_module.run_query(credentials, query, sql_params, opts) do
      data = DataHelper.rows_to_map(columns, rows)
      {:ok, %{columns: columns, data: data}}
    else
      {:error, reason} ->
        Logger.error("Failed to run query: #{inspect(reason)}")

        {:error, reason}
    end
  end

  # https://github.com/livebook-dev/kino_db/blob/main/lib/kino_db/sql_cell.ex#L234
  def parameterize_query(query, query_params, param_fun) do
    {parameterized_query, used_params} = do_parameterize(query, "", [], 1, param_fun)

    case used_params |> Enum.all?(&Map.has_key?(query_params, &1)) do
      true ->
        sql_params =
          used_params
          |> Enum.map(&Map.fetch!(query_params, &1))

        {:ok, {parameterized_query, sql_params}}

      false ->
        {:error, :missing_params}
    end
  end

  defp do_parameterize("", raw, params, _n, _next) do
    {raw, Enum.reverse(params)}
  end

  defp do_parameterize("--" <> _ = query, raw, params, n, next) do
    {comment, rest} =
      case String.split(query, "\n", parts: 2) do
        [comment, rest] -> {comment <> "\n", rest}
        [comment] -> {comment, ""}
      end

    do_parameterize(rest, raw <> comment, params, n, next)
  end

  defp do_parameterize("/*" <> _ = query, raw, params, n, next) do
    {comment, rest} =
      case String.split(query, "*/", parts: 2) do
        [comment, rest] -> {comment <> "*/", rest}
        [comment] -> {comment, ""}
      end

    do_parameterize(rest, raw <> comment, params, n, next)
  end

  defp do_parameterize("{{" <> rest = query, raw, params, n, next) do
    with [param, rest] <- String.split(rest, "}}", parts: 2) do
      do_parameterize(rest, raw <> next.(n), [param | params], n + 1, next)
    else
      _ -> do_parameterize("", raw <> query, params, n, next)
    end
  end

  defp do_parameterize(<<char::utf8, rest::binary>>, raw, params, n, next) do
    do_parameterize(rest, <<raw::binary, char::utf8>>, params, n, next)
  end
end
