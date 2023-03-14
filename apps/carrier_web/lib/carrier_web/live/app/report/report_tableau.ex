defmodule CarrierWeb.App.ReportLive.New.ReportTableau do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :user_id, :integer
    field :name, :string
    field :hour, :string
    field :trigger_time, :time
    field :timezone, :string

    embeds_one :integration_info, IntegrationInfo, primary_key: false, on_replace: :delete do
      field :integration_id, :integer
      field :channel_id, :string
      field :channel_name, :string
    end

    embeds_one :data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete do
      field :data_source_id, :integer
      field :source, Ecto.Enum, values: [:tableau]
      field :view_id, :string
      field :view_full_name, :string
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
    :view_id,
    :view_full_name
  ]
  defp changeset_data_source_info(%__MODULE__.DataSourceInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_data_source_info)
    |> validate_required(@required_data_source_info)
  end
end
