defmodule CarrierWeb.DataSourceLive.ConnInfoParams.Postgres do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conn_info" do
    field :name, :string
    field :hostname, :string
    field :port, :integer, default: 5432
    field :database, :string
    field :username, :string
    field :password, :string
  end

  @required [:name, :hostname, :port, :database, :username, :password]
  def changeset(%__MODULE__{} = struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
