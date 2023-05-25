defmodule Carrier.Reports.DataSourceInfo.Tableau do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:tableau]

    embeds_many :views, View, primary_key: false, on_replace: :delete do
      field :id, :string
    end
  end

  @required_for_create [
    :data_source_id,
    :source
  ]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  @required_view [:id]
  defp changeset_view(%__MODULE__.View{} = struct, attrs) do
    struct
    |> cast(attrs, @required_view)
    |> validate_required(@required_view)
  end
end
