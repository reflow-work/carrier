defmodule Carrier.Secrets.ConnInfo.Slack do
  use Carrier.Secrets.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :team_name, :string
    field :team_id, :string
    field :bot_token, :string
  end

  @impl true
  @required [:team_name, :team_id, :bot_token]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
