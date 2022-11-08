defmodule Carrier.Secrets.ConnInfo.MySQL do
  use Carrier.Secrets.ConnInfo.Info

  embedded_schema do
    field :hostname, :string
    field :port, :integer, default: 3306
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
      FROM information_schema.tables
      WHERE TABLE_SCHEMA not in ('mysql', 'performance_schema', 'sys', 'information_schema');
    """
  end

  def table_name_field() do
    "TABLE_NAME"
  end

  def columns_query() do
    """
    SELECT *
      FROM information_schema.columns
      WHERE TABLE_NAME = ?
      ORDER BY ORDINAL_POSITION;
    """
  end

  def column_name_field() do
    "COLUMN_NAME"
  end

  def data_type_field() do
    "DATA_TYPE"
  end

  def is_date_type?(type) do
    type in ["date", "datetime", "timestamp"]
  end
end
