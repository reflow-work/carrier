defmodule Carrier.Reports.DataSourceInfo.Tableau do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:tableau]

    embeds_one :params, Params, primary_key: false, on_replace: :delete do
      embeds_many :views, View, primary_key: false, on_replace: :delete do
        field :id, :string
      end
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
    |> cast_embed(:params, required: true, with: &changeset_params/2)
  end

  @required_params []
  def changeset_params(%__MODULE__.Params{} = struct, attrs) do
    struct
    |> cast(attrs, @required_params)
    |> validate_required(@required_params)
    |> cast_embed(:views, required: true, with: &changeset_view/2)
  end

  @required_view [:id]
  defp changeset_view(%__MODULE__.Params.View{} = struct, attrs) do
    struct
    |> cast(attrs, @required_view)
    |> validate_required(@required_view)
  end
end
