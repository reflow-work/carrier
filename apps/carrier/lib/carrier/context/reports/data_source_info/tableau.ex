defmodule Carrier.Reports.DataSourceInfo.Tableau do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_source_id, :integer
    field :source, Ecto.Enum, values: [:tableau]
    field :view_id, :string
    field :view_full_name, :string
  end

  @required_for_create [
    :data_source_id,
    :source,
    :view_id,
    :view_full_name
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end
end
