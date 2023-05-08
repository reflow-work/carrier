defmodule Carrier.Data.Source do
  @callback load_raw_data(data_source :: map(), params :: map()) :: {:ok, list()}
  @callback transform_data(data_source :: map(), raw_data :: list()) :: {:ok, list()}
  @callback data_to_blocks(data_source :: map(), data :: list()) :: {:ok, list()}

  use Carrier.Integrations

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
      alias unquote(__MODULE__).Tableau
    end
  end

  def load_raw_data(%DataSource{} = _data_source, _params) do
    {:ok, []}
  end

  def transform_data(%DataSource{} = _data_source, raw_data) do
    data =
      raw_data
      |> Enum.map(& &1)

    {:ok, data}
  end

  def data_to_blocks(%DataSource{} = _data_source, data) do
    blocks =
      data
      |> Enum.map(& &1)

    {:ok, blocks}
  end

  # TODO: move to Data.Source.RDS

  require Logger
  alias Carrier.Data.Source
  alias Carrier.Core.DataHelper

  def get_module(source) do
    case source do
      :postgres -> Source.Postgres
      :mysql -> Source.MySQL
      :bigquery -> Source.BigQuery
      :athena -> Source.Athena
    end
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
