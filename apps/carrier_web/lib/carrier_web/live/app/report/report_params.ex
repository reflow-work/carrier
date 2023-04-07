defmodule CarrierWeb.App.ReportLive.New.ReportParams do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :hour, :string
    field :trigger_time, :time
    field :timezone, :string

    embeds_one :integration_info, IntegrationInfo, primary_key: false, on_replace: :delete do
      field :integration_id, :id
      field :channel_id, :string
      field :channel_name, :string
    end

    embeds_one :data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete do
      field :data_source_id, :id
      field :source, Ecto.Enum, values: [:postgres, :mysql, :bigquery, :athena]
      field :sql_template, :string
      field :period, :integer
      field :window_size, :integer
      field :comparing_period, :integer
      field :columns, {:array, :string}
    end
  end

  @required [:org_id, :user_id, :name, :hour, :trigger_time, :timezone]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:integration_info, required: true, with: &changeset_interation_info/2)
    |> cast_embed(:data_source_info, required: true, with: &changeset_data_source_info/2)
  end

  def init_attrs(attrs \\ %{}) do
    attrs
  end

  @required_integration_info [:integration_id, :channel_id, :channel_name]
  defp changeset_interation_info(%__MODULE__.IntegrationInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_integration_info)
    |> validate_required(@required_integration_info)
  end

  @required_data_source_info [
    :data_source_id,
    :source,
    :sql_template,
    :period,
    :window_size,
    :comparing_period,
    :columns
  ]
  defp changeset_data_source_info(%__MODULE__.DataSourceInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_data_source_info)
    |> validate_required(@required_data_source_info)
    |> validate_length(:columns, min: 1)
  end
end
