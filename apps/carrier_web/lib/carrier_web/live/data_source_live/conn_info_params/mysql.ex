defmodule CarrierWeb.DataSourceLive.ConnInfoParams.MySQL do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :name, :string
    field :source, Ecto.Enum, values: [:mysql], default: :mysql
    field :hostname, :string
    field :port, :integer
    field :database, :string
    field :username, :string
    field :password, :string
  end

  @required [:org_id, :name, :hostname, :port, :database, :username, :password]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def init_attrs() do
    %{port: 3306}
  end
end
