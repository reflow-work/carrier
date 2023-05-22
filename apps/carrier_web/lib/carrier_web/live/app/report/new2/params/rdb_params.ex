defmodule CarrierWeb.App.ReportLive.New2.RDBParams do
  use Ecto.Schema
  use Doumi.Phoenix.Params, as: :rdb
  import Ecto.Changeset

  embedded_schema do
    field :sql_template, :string
    field :unit, Ecto.Enum, values: [:day]

    embeds_many :charts, Chart, primary_key: false, on_replace: :delete do
      field :name, :string
      field :period_value, :integer

      embeds_many :metrics, Metric, primary_key: false, on_replace: :delete do
        field :name, :string
        field :column, :string
        field :window_size, :integer
        field :period_over_period_unit, Ecto.Enum, values: [:week]
      end
    end
  end

  @required [:sql_template, :unit]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> cast_embed(:charts,
      with: &chart_changeset/2,
      sort_param: :chart_order,
      drop_param: :chart_delete,
      required: true
    )
  end

  @chart_required [:name, :period_value]
  def chart_changeset(%__MODULE__.Chart{} = struct, attrs) do
    struct
    |> cast(attrs, @chart_required)
    |> validate_required(@chart_required)
    |> cast_embed(:metrics, with: &metric_changeset/2, required: true)
  end

  @metric_required [:name, :column, :window_size]
  @metric_optional [:period_over_period_unit]
  def metric_changeset(%__MODULE__.Chart.Metric{} = struct, attrs) do
    struct
    |> cast(attrs, @metric_required ++ @metric_optional)
    |> validate_required(@metric_required)
  end
end
