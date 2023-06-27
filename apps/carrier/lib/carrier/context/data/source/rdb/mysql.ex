defmodule Carrier.Data.Source.RDB.MySQL do
  @behaviour Carrier.Data.Source.RDB

  require Logger
  alias Carrier.Dynamic.MySQLRepo

  @impl Carrier.Data.Source.RDB
  def validation_query() do
    "SELECT 1"
  end

  @impl Carrier.Data.Source.RDB
  def param(_n) do
    "?"
  end

  @impl Carrier.Data.Source.RDB
  def run_query(credentials, sql, sql_params \\ [], opts \\ []) do
    %{columns: columns, rows: rows} =
      MySQLRepo.with_dynamic_repo(credentials, opts, fn ->
        MySQLRepo.query!(sql, sql_params)
      end)

    {:ok, %{columns: columns, rows: rows}}
  rescue
    e in MyXQL.Error ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      %MyXQL.Error{message: message} = e

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
      WHERE TABLE_SCHEMA not in ('mysql', 'performance_schema', 'sys', 'information_schema');
    """
  end

  @impl Carrier.Data.Source.RDB
  def table_name_field() do
    "TABLE_NAME"
  end

  @impl Carrier.Data.Source.RDB
  def columns_query() do
    """
    SELECT #{column_name_field()}, #{data_type_field()}
      FROM information_schema.columns
      WHERE TABLE_NAME = {{table_name}}
      ORDER BY ORDINAL_POSITION;
    """
  end

  @impl Carrier.Data.Source.RDB
  def column_name_field() do
    "COLUMN_NAME"
  end

  @impl Carrier.Data.Source.RDB
  def data_type_field() do
    "DATA_TYPE"
  end

  @impl Carrier.Data.Source.RDB
  def is_date_type?(type) do
    type in ["date", "datetime", "timestamp"]
  end
end
