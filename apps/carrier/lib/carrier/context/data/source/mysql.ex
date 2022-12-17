defmodule Carrier.Data.Source.MySQL do
  @behaviour Carrier.Data.Source.RDB

  alias Carrier.Dynamic.MySQLRepo

  @impl Carrier.Data.Source.RDB
  def tables_query() do
    """
    SELECT *
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
    SELECT *
      FROM information_schema.columns
      WHERE TABLE_NAME = ?
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

  @impl Carrier.Data.Source.RDB
  def run_query(credentials, sql, sql_params \\ []) do
    %{columns: columns, rows: rows} =
      MySQLRepo.with_dynamic_repo(credentials, fn ->
        MySQLRepo.query!(sql, sql_params)
      end)

    {:ok, %{columns: columns, rows: rows}}
  rescue
    error in MyXQL.Error ->
      %MyXQL.Error{message: message} = error

      {:error, {:query_error, message}}
  end
end
