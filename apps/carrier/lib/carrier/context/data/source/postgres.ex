defmodule Carrier.Data.Source.Postgres do
  @behaviour Carrier.Data.Source.RDB

  alias Carrier.Dynamic.PostgresRepo

  @impl Carrier.Data.Source.RDB
  def tables_query() do
    """
    SELECT table_schema, table_name
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
    SELECT *
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = $1
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

  @impl Carrier.Data.Source.RDB
  def run_query(credentials, sql, sql_params \\ []) do
    %{columns: columns, rows: rows} =
      PostgresRepo.with_dynamic_repo(credentials, fn ->
        PostgresRepo.query!(sql, sql_params)
      end)

    {:ok, %{columns: columns, rows: rows}}
  rescue
    error in Postgrex.Error ->
      %Postgrex.Error{postgres: %{message: message}} = error

      {:error, {:query_error, message}}
  end
end
