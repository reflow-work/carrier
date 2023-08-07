defmodule Carrier.Reports.DataSourceInfo.Amplitude do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :data_source_id, :id
    field :source, Ecto.Enum, values: [:amplitude]

    embeds_one :params, Params, primary_key: false, on_replace: :delete do
      embeds_many :dashboards, Dashboard, primary_key: false, on_replace: :delete do
        field :name, :string
        field :url, :string
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
    |> cast_embed(:dashboards, required: true, with: &changeset_dashboard/2)
  end

  @required_dashboard [:name, :url]
  defp changeset_dashboard(%__MODULE__.Params.Dashboard{} = struct, attrs) do
    struct
    |> cast(attrs, @required_dashboard)
    |> validate_required(@required_dashboard)
  end
end
