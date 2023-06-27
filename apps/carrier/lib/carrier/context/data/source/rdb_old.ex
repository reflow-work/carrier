defmodule Carrier.Data.Source.RDBOld do
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
  alias Carrier.Data.QueryData
  alias Carrier.Data.Block
  alias Carrier.Reports.ImageGenerator
  alias Carrier.Core.{Crypto, DateHelper}

  @impl true
  def validate_conn(source, credentials, opts) do
    query = get_module(source, false).validation_query()

    case do_run_query(source, false, credentials, query, [], opts) do
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
        %{
          data_source_info: %{
            sql_template: sql_template,
            period: period,
            window_size: window_size,
            comparing_period: comparing_period
          },
          datetime: utc_datetime,
          timezone: timezone
        },
        %DataSource{} = data_source
      ) do
    {query_start_date, query_end_date} =
      calc_query_start_end_date(%{
        datetime: utc_datetime,
        timezone: timezone,
        period: period,
        window_size: window_size,
        comparing_period: comparing_period
      })

    query_params = %{"start" => query_start_date, "end" => query_end_date}

    with :ok <- is_valid_sql?(sql_template),
         {:ok, %{columns: columns, data: data} = query_result} <-
           run_query(data_source, sql_template, query_params),
         :ok <- validate_query_result(query_result) do
      data =
        data
        |> normalize_data()
        |> fill_missing_dates(columns, query_start_date, query_end_date)

      {:ok, %{columns: columns, data: data}}
    end
  end

  @impl true
  def transform_data(
        %{
          org_id: org_id,
          data_source_info: %{
            period: period,
            window_size: window_size,
            comparing_period: comparing_period,
            columns: selected_columns
          }
        },
        _data_source,
        %{columns: columns, data: data}
      ) do
    {:ok, analyzed_data} =
      QueryData.analyze(data, %{
        columns: columns,
        period: period,
        window_size: window_size,
        comparing_period: comparing_period
      })

    parsed_data =
      QueryData.refine_data_based_on_columns(
        %{columns: columns, data: analyzed_data},
        selected_columns,
        window_size
      )

    fake_report_id = Crypto.random_string(8)

    with {:ok, %{image_urls: image_urls}} <-
           ImageGenerator.gen_chart_images(%{
             org_id: org_id,
             report_id: fake_report_id,
             data: parsed_data
           }) do
      {:ok, %{image_urls: image_urls}}
    end
  end

  @impl true
  def data_to_threads(
        %{
          data_source_info: %{
            columns: selected_columns
          },
          timezone: timezone
        },
        _data_source,
        %{image_urls: image_urls}
      ) do
    threads =
      selected_columns
      |> Enum.map(fn column ->
        image_url = image_urls |> Map.get(column)

        [
          Block.text(title(column, timezone)),
          Block.image(column, image_url, column)
        ]
      end)

    {:ok, threads}
  end

  defp calc_query_start_end_date(%{
         datetime: utc_datetime,
         timezone: timezone,
         period: period,
         comparing_period: comparing_period,
         window_size: window_size
       }) do
    query_end_date =
      utc_datetime
      |> DateTime.shift_zone!(timezone)
      |> DateTime.to_date()

    query_start_date = query_end_date |> Date.add(-(period + comparing_period + window_size + 1))

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

  def title(column, timezone) do
    "📊 #{DateTime.now!(timezone) |> DateHelper.safe_format_date()} - #{column}"
  end

  require Logger
  alias Carrier.Core.DataHelper

  def sources() do
    [:postgres, :mysql, :bigquery, :athena]
  end

  def get_module(:postgres, true) do
    Carrier.Data.Source.RDB.PostgresDemo
  end

  def get_module(source, false) when is_atom(source) do
    case source do
      :postgres -> Carrier.Data.Source.RDB.Postgres
      :mysql -> Carrier.Data.Source.RDB.MySQL
      :bigquery -> Carrier.Data.Source.RDB.BigQuery
      :athena -> Carrier.Data.Source.RDB.Athena
    end
  end

  def run_query(
        %DataSource{source: source, demo: demo} = data_source,
        query,
        query_params \\ %{},
        opts \\ []
      ) do
    credentials = DataSource.to_credentials(data_source)

    do_run_query(source, demo, credentials, query, query_params, opts)
  end

  def do_run_query(source, demo, credentials, query, query_params \\ %{}, opts \\ []) do
    source_module = get_module(source, demo)

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
