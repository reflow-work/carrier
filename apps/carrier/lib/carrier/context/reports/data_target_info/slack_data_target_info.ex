defmodule Carrier.Reports.DataTargetInfo.SlackDataTargetInfo do
  use Carrier.Schema

  @primary_key false
  embedded_schema do
    field :channel_id, :string
    field :channel_name, :string
    field :channel_type, Ecto.Enum, values: [:public_channel, :private_channel, :direct_message]
  end

  @required [:channel_id, :channel_name, :channel_type]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  # TODO: duplicated with Data.Slack.Channel.to_string/1
  def to_string(%__MODULE__{channel_name: channel_name, channel_type: channel_type}) do
    prefix =
      case channel_type do
        :public_channel -> "#"
        :private_channel -> "🔒"
        :direct_message -> "@"
        # fallback
        _ -> "#"
      end

    prefix <> channel_name
  end

  def to_params(params) do
    changeset(%__MODULE__{}, params)
    |> apply_changes()
  end
end
