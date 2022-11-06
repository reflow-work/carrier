defmodule Carrier.Secrets.ConnInfo.Postgres do
  use Carrier.Secrets.ConnInfo.Info

  embedded_schema do
    field :hostname, :string
    field :port, :integer, default: 5432
    field :username, :string
    field :password, :string, redact: true
    field :database, :string
    field :ssl, :boolean, default: false
  end

  @impl true
  @required [:hostname, :port, :username, :password, :database, :ssl]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def tables_query() do
    """
    SELECT *
      FROM pg_catalog.pg_tables
      WHERE schemaname != 'pg_catalog' AND
          schemaname != 'information_schema'
    """
  end

  def columns_query() do
    """
    SELECT
      column_name,
      data_type
    FROM
      information_schema.columns
    WHERE
      table_name = $1;
    """
  end

  def is_date_type?(type) do
    cond do
      type == "date" -> true
      type |> String.starts_with?("timestamp") -> true
      true -> false
    end
  end
end
