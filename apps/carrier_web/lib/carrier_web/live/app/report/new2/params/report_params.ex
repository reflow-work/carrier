defmodule CarrierWeb.App.ReportLive.New2.ReportParams do
  use Ecto.Schema
  use Doumi.Phoenix.Params, as: :report
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :interval, Ecto.Enum, values: [:hourly, :daily]
    # TODO: change with map to support more intervals
    field :trigger_time, :time
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
    :trigger_time
  ]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
