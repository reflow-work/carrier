defmodule CarrierWeb.App.ReportLive.New2.ReportParams do
  use Ecto.Schema
  use Doumi.Phoenix.Params, as: :report
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :text, :string
    field :interval, Ecto.Enum, values: [:hourly, :daily, :weekly]
    # TODO: change with map to support more intervals
    field :trigger_time, :time
    field :trigger_minute, :integer
    field :trigger_weekday, :integer
    field :timezone, :string
  end

  @required [
    :org_id,
    :user_id,
    :name,
    :interval,
    :timezone
  ]
  @optional [
    :text,
    :trigger_time,
    :trigger_minute,
    :trigger_weekday
  ]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
