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
    SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
    """
  end

  def table_name_field() do
    "table_name"
  end

  def columns_query() do
    """
    SELECT *
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = $1
      ORDER BY ordinal_position;
    """
  end

  def column_name_field() do
    "column_name"
  end

  def data_type_field() do
    "data_type"
  end

  def is_date_type?(type) do
    cond do
      type == "date" -> true
      type |> String.starts_with?("timestamp") -> true
      true -> false
    end
  end
end
