defmodule Carrier.Data.Source.RDB.MySQL do
  @behaviour Carrier.Data.Source.RDB

  require Logger
  alias Carrier.Dynamic.MySQLRepo

  @impl Carrier.Data.Source.RDB
  def validate_conn(credentials) do
    opts =
      Keyword.new(credentials) ++
        [disconnect_on_error_codes: [1461], connect_timeout: 3000, pool_size: 1]

    case MyXQL.Connection.connect(opts) do
      {:ok, state} ->
        MyXQL.Connection.disconnect(nil, state)

        :ok

      {:error, %DBConnection.ConnectionError{message: message}} ->
        # hostname, port error
        # "tcp connect (localhost1:48140): non-existing domain - :nxdomain"
        # timeout(firewall) error
        # "tcp connect (reflow-carrier-app-db.cdw6skjbo8fk.ap-northeast-2.rds.amazonaws.com:48140): timeout"

        Logger.warning(message)

        {:error, {:invalid_conn_info, message}}

      {:error, %MyXQL.Error{message: message}} ->
        # username, password, database error
        # "Access denied for user 'root1'@'172.30.0.1' (using password: YES)"

        Logger.warning(message)

        {:error, {:invalid_conn_info, message}}
    end
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
