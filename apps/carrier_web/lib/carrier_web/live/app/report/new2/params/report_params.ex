defmodule CarrierWeb.App.ReportLive.New2.ReportParams do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :interval, Ecto.Enum, values: [:daily]
    field :trigger_time, :time
    field :timezone, :string
    field :data_source_info, :map
    field :data_target_info, :map
  end

  @required [
    :org_id,
    :user_id,
    :name,
    :trigger_time,
    :timezone,
    :data_source_info,
    :data_target_info
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
