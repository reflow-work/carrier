defmodule Carrier.Secrets.ConnInfo.Athena do
  use Carrier.Secrets.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :access_key_id, :string
    field :secret_access_key, :string
    field :region, :string
    field :workgroup, :string
    field :database, :string
  end

  @impl true
  @required [
    :access_key_id,
    :secret_access_key,
    :region,
    :workgroup,
    :database
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
