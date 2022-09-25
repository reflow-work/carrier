defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema

  schema "report_logs" do
    field :org_id, :integer
    field :report_id, :integer
    field :payload, :map
    field :tried_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :error_message, :string

    embeds_one(:integration_info, IntegrationInfo, primary_key: false, on_replace: :delete) do
      @derive Jason.Encoder
      field :integration_id, :integer
      field :channel_id, :string
      field :channel_name, :string
    end

    embeds_one(:data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete) do
      @derive Jason.Encoder
      field :data_source_id, :integer
      field :sql_template, :string
      field :timezone, :string
      field :period, :integer
      field :window_size, :integer
      field :comparing_period, :integer
      field :columns, {:array, :string}
    end
  end

  @required_for_create [:org_id, :report_id, :payload, :tried_at]
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

  @required_for_create_integration_info [:integration_id, :channel_id, :channel_name]
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

  @required_for_record_succeeded [:sent_at]
  defp changeset_for_record_succeeded(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_record_succeeded)
    |> validate_required(@required_for_record_succeeded)
  end

  @required_for_record_failed [:error_message]
  defp changeset_for_record_failed(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_record_failed)
    |> validate_required(@required_for_record_failed)
  end

  def create(%{
        org_id: org_id,
        report_id: report_id,
        payload: payload,
        tried_at: tried_at,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      report_id: report_id,
      payload: payload,
      tried_at: tried_at,
      integration_info: integration_info,
      data_source_info: data_source_info
    })
  end

  def record_succeeded(%__MODULE__{} = struct, %{
        sent_at: sent_at
      }) do
    struct
    |> changeset_for_record_succeeded(%{
      sent_at: sent_at
    })
  end

  def record_failed(%__MODULE__{} = struct, %{
        error_message: error_message
      }) do
    struct
    |> changeset_for_record_failed(%{
      error_message: error_message
    })
  end
end
