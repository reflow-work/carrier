defmodule Carrier.Secrets.ConnInfo.BigQuery do
  use Carrier.Secrets.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :project_id, :string
    field :credentials_json, :string
  end

  @impl true
  @required [:project_id, :credentials_json]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
