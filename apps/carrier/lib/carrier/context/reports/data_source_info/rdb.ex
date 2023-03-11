defmodule Carrier.Reports.DataSourceInfo.RDB do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_source_id, :integer
    field :source, Ecto.Enum, values: [:postgres, :mysql, :bigquery, :athena]
    field :sql_template, :string
    field :timezone, :string
    field :period, :integer
    field :window_size, :integer
    field :comparing_period, :integer
    field :columns, {:array, :string}
  end

  @required_for_create [
    :data_source_id,
    :source,
    :sql_template,
    :timezone,
    :period,
    :window_size,
    :comparing_period,
    :columns
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end
end
