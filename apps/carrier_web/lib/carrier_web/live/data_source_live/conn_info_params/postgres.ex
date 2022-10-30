defmodule CarrierWeb.DataSourceLive.ConnInfoParams.Postgres do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :name, :string
    field :source, Ecto.Enum, values: [:postgres], default: :postgres
    field :hostname, :string
    field :port, :integer
    field :database, :string
    field :username, :string
    field :password, :string
    field :ssl, :boolean
  end

  @required [:org_id, :name, :hostname, :port, :database, :username, :password, :ssl]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def init_attrs() do
    %{port: 5432, ssl: false}
  end
end
