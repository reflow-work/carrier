defmodule Carrier.Reports.DataTargetInfo do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :integration_id, :id
    field :channel_id, :string
    field :channel_name, :string
  end

  @required_for_create [:integration_id, :channel_id, :channel_name]
  def changeset_for_create(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end
end
