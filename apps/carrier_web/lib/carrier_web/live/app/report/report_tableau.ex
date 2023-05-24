defmodule CarrierWeb.App.ReportLive.New.ReportTableau do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :hour, :string
    field :interval, Ecto.Enum, values: [:daily], default: :daily
    field :trigger_time, :time
    field :timezone, :string

    embeds_one :data_target_info, DataTargetInfo, primary_key: false, on_replace: :delete do
      field :data_target_id, :id
      field :target, Ecto.Enum, values: [:slack], default: :slack

      embeds_one :params, Params, primary_key: false, on_replace: :delete do
        field :channel_id, :string
        field :channel_name, :string
      end
    end

    embeds_one :data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete do
      field :data_source_id, :id
      field :source, Ecto.Enum, values: [:tableau]
      field :view_id, :string
      field :view_full_name, :string
    end
  end

  @required [:org_id, :user_id, :name, :hour, :interval, :trigger_time, :timezone]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:data_target_info, required: true, with: &changeset_data_target_info/2)
    |> cast_embed(:data_source_info, required: true, with: &changeset_data_source_info/2)
  end

  def init_attrs(attrs \\ %{}) do
    attrs
  end

  @required_data_target_info [:data_target_id, :target]
  defp changeset_data_target_info(%__MODULE__.DataTargetInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_data_target_info)
    |> validate_required(@required_data_target_info)
    |> cast_embed(:params, required: true, with: &changeset_params/2)
  end

  @required_params [:channel_id, :channel_name]
  defp changeset_params(%__MODULE__.DataTargetInfo.Params{} = struct, attrs) do
    struct
    |> cast(attrs, @required_params)
    |> validate_required(@required_params)
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
