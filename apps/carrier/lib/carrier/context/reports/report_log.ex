defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema
  alias Carrier.Reports.{IntegrationInfo, DataSourceInfo}

  schema "report_logs" do
    field :org_id, :integer
    field :report_id, :integer
    field :payload, :map
    field :tried_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :error_message, :string

    embeds_one :integration_info, IntegrationInfo, on_replace: :delete
    embeds_one :data_source_info, DataSourceInfo, on_replace: :delete
  end

  @required_for_create [:org_id, :report_id, :payload, :tried_at]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> cast_embed(:integration_info,
      required: true,
      with: &IntegrationInfo.changeset_for_create/2
    )
    |> cast_embed(:data_source_info,
      required: true,
      with: &DataSourceInfo.changeset_for_create/2
    )
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
