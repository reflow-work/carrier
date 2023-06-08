defmodule Carrier.Integrations.ConnInfo.Slack do
  use Carrier.Integrations.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :bot_scope, :string
    field :bot_token, :string
    field :team_id, :string
    field :team_name, :string
  end

  @impl true
  @required [
    :bot_scope,
    :bot_token,
    :team_id,
    :team_name
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
