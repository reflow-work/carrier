defmodule Carrier.Reports.Report do
  use Carrier.Schema
  alias Carrier.Reports.{ReportInfo, DataTargetInfo, DataSourceInfo, ReportLog}

  @derive Carrier.Obfuscatable.Protocol

  schema "reports" do
    belongs_to :report_info, ReportInfo
    has_one :last_report_log, ReportLog

    field :org_id, :id
    field :user_id, :id
    field :name, :string
    field :text, :string
    field :interval, Ecto.Enum, values: [:hourly, :daily, :weekly]
    # TODO: remove read_after_writes option
    field :trigger_minute, :integer, read_after_writes: true
    field :trigger_time, :time
    field :trigger_weekday, :integer
    field :timezone, :string

    field :data_source_info, :map
    embeds_one :data_target_info, DataTargetInfo, on_replace: :delete

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [
    :org_id,
    :report_info_id,
    :user_id,
    :name,
    :interval,
    :timezone,
    :data_source_info
  ]
  @optional_for_create [:text, :trigger_time, :trigger_weekday]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create ++ @optional_for_create)
    |> validate_required(@required_for_create)
    |> cast_embed(:data_target_info,
      required: true,
      with: &DataTargetInfo.changeset/2
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

  def create(params) do
    %__MODULE__{}
    |> changeset_for_create(params)
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

  def load_fields(%__MODULE__{} = struct) do
    struct
    |> load_data_source_info()
    |> load_data_target_info()
  end

  defp load_data_source_info(%__MODULE__{data_source_info: data_source_info} = struct) do
    data_source_info =
      data_source_info
      |> DataSourceInfo.get_struct()

    %__MODULE__{struct | data_source_info: data_source_info}
  end

  defp load_data_target_info(%__MODULE__{data_target_info: data_target_info} = struct) do
    data_target_info = data_target_info |> DataTargetInfo.load_params()

    %__MODULE__{struct | data_target_info: data_target_info}
  end
end
