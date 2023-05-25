defmodule Carrier.Reports.DataTargetInfo.SlackDataTargetInfo do
  use Carrier.Schema

  @primary_key false
  embedded_schema do
    field :channel_id, :string
    field :channel_name, :string
  end

  @required [:channel_id, :channel_name]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def to_string(%__MODULE__{channel_name: channel_name}) do
    "# #{channel_name}"
  end

  def to_params(params) do
    changeset(%__MODULE__{}, params)
    |> apply_changes()
  end
end
