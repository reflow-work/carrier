defmodule Carrier.Secrets.ConnInfo.Slack do
  use Carrier.Secrets.ConnInfo.Info

  embedded_schema do
    field :team_name, :string
    field :team_id, :string
  end

  @impl true
  @required [:team_name, :team_id]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
