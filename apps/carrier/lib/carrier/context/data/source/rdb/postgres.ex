defmodule Carrier.Data.Source.RDB.Postgres do
  @behaviour Carrier.Data.Source.RDB

  require Logger
  alias Carrier.Dynamic.PostgresRepo

  @impl Carrier.Data.Source.RDB
  def validation_query() do
    "SELECT 1"
  end

  @impl Carrier.Data.Source.RDB
  def param(n) do
    "$#{n}"
  end

  @impl Carrier.Data.Source.RDB
  def run_query(credentials, sql, sql_params \\ [], opts \\ []) do
    %{columns: columns, rows: rows} =
      PostgresRepo.with_dynamic_repo(credentials, opts, fn ->
        PostgresRepo.query!(sql, sql_params)
      end)

    {:ok, %{columns: columns, rows: rows}}
  rescue
    e in Postgrex.Error ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      %Postgrex.Error{postgres: %{message: message}} = e

      {:error, {:query_error, message}}

    e in DBConnection.ConnectionError ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      {:error, :db_connection_error}
  end

  @impl Carrier.Data.Source.RDB
  def tables_query() do
    """
    SELECT #{table_name_field()}
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
    """
  end

  @impl Carrier.Data.Source.RDB
  def table_name_field() do
    "table_name"
  end

  @impl Carrier.Data.Source.RDB
  def columns_query() do
    """
    SELECT #{column_name_field()}, #{data_type_field()}
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = {{table_name}}
      ORDER BY ordinal_position;
    """
  end

  @impl Carrier.Data.Source.RDB
  def column_name_field() do
    "column_name"
  end

  @impl Carrier.Data.Source.RDB
  def data_type_field() do
    "data_type"
  end

  @impl Carrier.Data.Source.RDB
  def is_date_type?(type) do
    cond do
      type == "date" -> true
      type |> String.starts_with?("timestamp") -> true
      true -> false
    end
  end
end
