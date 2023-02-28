defmodule Carrier.Secrets.ConnInfo.MySQL do
  use Carrier.Secrets.ConnInfo.Info

  @primary_key false
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
end
