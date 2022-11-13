defmodule Carrier.Reports.Report do
  use Carrier.Schema
  alias Carrier.Reports.{ReportInfo, IntegrationInfo, DataSourceInfo}

  schema "reports" do
    belongs_to :report_info, ReportInfo

    field :org_id, :integer
    field :user_id, :integer
    field :name, :string
    field :trigger_time, :time

    embeds_one :integration_info, IntegrationInfo, on_replace: :delete
    embeds_one :data_source_info, DataSourceInfo, on_replace: :delete

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :report_info_id, :user_id, :name, :trigger_time]
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

  @required_for_delete [:deleted_at]
  defp changeset_for_delete(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_delete)
    |> validate_required(@required_for_delete)
  end

  def create(%{
        org_id: org_id,
        report_info_id: report_info_id,
        user_id: user_id,
        name: name,
        trigger_time: trigger_time,
        integration_info: integration_info,
        data_source_info: data_source_info
      }) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      report_info_id: report_info_id,
      user_id: user_id,
      name: name,
      trigger_time: trigger_time,
      integration_info: integration_info,
      data_source_info: data_source_info
    })
  end

  def list() do
    __MODULE__
    |> join(:inner, [r], ri in assoc(r, :report_info))
    |> distinct([r], r.report_info_id)
    |> query_not_deleted()
    |> order_by([r], desc: r.created_at)
  end

  def fetch(report_id) do
    __MODULE__
    |> join(:inner, [r], ri in assoc(r, :report_info))
    |> where([r], r.id == ^report_id)
    |> query_not_deleted()
  end

  def delete(%__MODULE__{} = struct, %DateTime{} = deleted_at) do
    struct
    |> changeset_for_delete(%{deleted_at: deleted_at})
  end

  defp query_not_deleted(query) do
    query
    |> where([r, ri], is_nil(ri.deleted_at))
  end
end
