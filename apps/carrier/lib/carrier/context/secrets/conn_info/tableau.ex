defmodule Carrier.Secrets.ConnInfo.Tableau do
  use Carrier.Secrets.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :host, :string
    field :id, :string
    field :password, :string
    field :site, :string
  end

  @impl true
  @required [:host, :id, :password, :site]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
