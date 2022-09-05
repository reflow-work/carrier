defmodule Carrier.Reports.Report do
  use Carrier.Schema

  schema "reports" do
    field :org_id, :integer
    field :name, :string
    field :trigger_time, :time

    embeds_one(:integration_info, IntegrationInfo, primary_key: false, on_replace: :delete) do
      field :integration_id, :integer
      field :channel_id, :string
    end

    embeds_one(:data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete) do
      field :data_source_id, :integer
      field :sql_template, :string
      field :timezone, :string
      field :period, :integer
      field :window_size, :integer
      field :comparing_period, :integer
      field :columns, {:array, :string}
    end

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :name, :trigger_time]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> cast_embed(:integration_info,
      required: true,
      with: &changeset_for_create_integration_info/2
    )
    |> cast_embed(:data_source_info,
      required: true,
      with: &changeset_for_create_data_source_info/2
    )
  end

  @required_for_create_integration_info [:integration_id, :channel_id]
  defp changeset_for_create_integration_info(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create_integration_info)
    |> validate_required(@required_for_create_integration_info)
  end

  @required_for_create_data_source_info [
    :data_source_id,
    :sql_template,
    :timezone,
    :period,
    :window_size,
    :comparing_period,
    :columns
  ]
  defp changeset_for_create_data_source_info(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create_data_source_info)
    |> validate_required(@required_for_create_data_source_info)
  end

  @required_for_delete [:deleted_at]
  defp changeset_for_delete(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_delete)
    |> validate_required(@required_for_delete)
  end

  def create(%{
        org_id: org_id,
        name: name,
        trigger_time: trigger_time,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      name: name,
      trigger_time: trigger_time,
      integration_info: integration_info,
      data_source_info: data_source_info
    })
  end

  def list() do
    __MODULE__
    |> where([r], is_nil(r.deleted_at))
  end

  def fetch(report_id) do
    __MODULE__
    |> where([r], r.id == ^report_id)
  end

  def delete(%__MODULE__{} = struct, %DateTime{} = deleted_at) do
    struct
    |> changeset_for_delete(%{deleted_at: deleted_at})
  end
end
