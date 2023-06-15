defmodule CarrierWeb.App.ReportLive.New2.RDBParamsOld do
  use Ecto.Schema
  use Doumi.Phoenix.Params, as: :rdb
  import Ecto.Changeset

  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:postgres, :mysql, :bigquery, :athena]
    field :sql_template, :string
    field :period, :integer
    field :window_size, :integer
    field :comparing_period, :integer
    field :columns, {:array, :string}
  end

  @required [
    :data_source_id,
    :source,
    :sql_template,
    :period,
    :window_size,
    :comparing_period,
    :columns
  ]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_length(:columns, min: 1)
  end
end
