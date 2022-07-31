defmodule Carrier.Secrets.ConnInfo.MySQL do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :hostname, :string
    field :port, :integer, default: 5432
    field :username, :string
    field :password, :string
    field :database, :string
  end

  @required [:hostname, :port, :username, :password, :database]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
