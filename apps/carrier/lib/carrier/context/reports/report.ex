defmodule Carrier.Reports.Report do
  use Carrier.Schema
  alias Carrier.Reports.{ReportInfo, IntegrationInfo, DataSourceInfo}

  @derive Carrier.Obfuscatable.Protocol

  schema "reports" do
    belongs_to :report_info, ReportInfo

    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :trigger_time, :time
    field :timezone, :string

    embeds_one :integration_info, IntegrationInfo, on_replace: :delete
    field :data_source_info, :map

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [
    :org_id,
    :report_info_id,
    :user_id,
    :name,
    :trigger_time,
    :timezone,
    :data_source_info
  ]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> cast_embed(:integration_info,
      required: true,
      with: &IntegrationInfo.changeset_for_create/2
    )
    |> validate_data_source_info()
  end

  defp validate_data_source_info(%Ecto.Changeset{} = changeset) do
    validate_change(changeset, :data_source_info, fn :data_source_info, data_source_info ->
      data_source_info_changeset = DataSourceInfo.get_changeset(data_source_info)

      case data_source_info_changeset.valid? do
        true -> []
        false -> data_source_info_changeset.errors
      end
    end)
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
        timezone: timezone,
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
      timezone: timezone,
      integration_info: integration_info,
      data_source_info: data_source_info
    })
  end

  def list() do
    __MODULE__
    |> join(:inner, [r], ri in assoc(r, :report_info))
    |> distinct([r], r.report_info_id)
    |> where([r, ri], is_nil(ri.deleted_at))
    |> order_by([r], desc: r.created_at)
    |> select([r, ri], %{r | created_at: ri.created_at})
  end

  def fetch(report_id) do
    __MODULE__
    |> join(:inner, [r], ri in assoc(r, :report_info))
    |> where([r], r.id == ^report_id)
    |> where([r, ri], is_nil(r.deleted_at) and is_nil(ri.deleted_at))
  end

  def delete(%__MODULE__{} = struct, %DateTime{} = deleted_at) do
    struct
    |> changeset_for_delete(%{deleted_at: deleted_at})
  end

  def load_data_source_info(%__MODULE__{data_source_info: data_source_info} = struct) do
    data_source_info =
      data_source_info
      |> DataSourceInfo.get_struct()

    %__MODULE__{struct | data_source_info: data_source_info}
  end
end
