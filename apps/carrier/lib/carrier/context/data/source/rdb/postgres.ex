defmodule Carrier.Data.Source.RDB.Postgres do
  @behaviour Carrier.Data.Source.RDB

  require Logger
  alias Carrier.Dynamic.PostgresRepo

  @impl Carrier.Data.Source.RDB
  def validate_conn(credentials) do
    opts = Keyword.new(credentials) ++ [types: Postgrex.DefaultTypes, timeout: 3000, pool_size: 1]

    case Postgrex.Protocol.connect(opts) do
      {:ok, state} ->
        Postgrex.Protocol.disconnect(nil, state)

        :ok

      {:error, %DBConnection.ConnectionError{message: message}} ->
        # hostname, port error
        # "tcp connect (localhost1:48140): non-existing domain - :nxdomain"
        # timeout(firewall) error
        # "tcp connect (reflow-carrier-app-db.cdw6skjbo8fk.ap-northeast-2.rds.amazonaws.com:48140): timeout"

        Logger.warning(message)

        {:error, {:invalid_conn_info, message}}

      {:error, %Postgrex.Error{postgres: %{message: message}}} ->
        # username, password, database error
        # "tcp connect (localhost1:48140): non-existing domain - :nxdomain"

        Logger.warning(message)

        {:error, {:invalid_conn_info, message}}
    end
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      {:error, {:invalid_conn_info, "unknown error"}}
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
