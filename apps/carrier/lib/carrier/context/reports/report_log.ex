defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema
  alias Carrier.Reports.{ReportInfo, Report}

  schema "report_logs" do
    belongs_to :report_info, ReportInfo
    belongs_to :report, Report

    field :org_id, :id
    field :report_job_id, :id

    field :status, Ecto.Enum,
      values: [:scheduled, :tried, :succeeded, :failed, :cancelled],
      default: :scheduled

    field :created_at, :utc_datetime_usec
    field :scheduled_at, :utc_datetime_usec
    field :tried_at, :utc_datetime_usec
    field :succeeded_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec
    field :cancelled_at, :utc_datetime_usec
    field :payload, {:array, :any}
    field :error_message, :string
  end

  @required_for_record_scheduled [
    :org_id,
    :report_info_id,
    :report_id,
    :report_job_id,
    :created_at,
    :scheduled_at
  ]
  defp changeset_for_record_scheduled(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_record_scheduled)
    |> validate_required(@required_for_record_scheduled)
  end

  @optional_for_update [:payload]
  defp changeset_for_update(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @optional_for_update)
  end

  def record_scheduled(%{
        org_id: org_id,
        report_info_id: report_info_id,
        report_id: report_id,
        report_job_id: report_job_id,
        created_at: created_at,
        scheduled_at: scheduled_at
      }) do
    %__MODULE__{}
    |> changeset_for_record_scheduled(%{
      org_id: org_id,
      report_info_id: report_info_id,
      report_id: report_id,
      report_job_id: report_job_id,
      status: :scheduled,
      created_at: created_at,
      scheduled_at: scheduled_at
    })
  end

  def record_tried(%{report_id: report_id, tried_at: tried_at}) do
    __MODULE__
    |> where(
      [rl],
      rl.report_id == ^report_id and rl.status in [:scheduled, :failed]
    )
    |> update([rl], set: [status: :tried, tried_at: ^tried_at])
    |> select([rl], rl)
  end

  def record_succeeded(%{report_id: report_id, succeeded_at: succeeded_at}) do
    __MODULE__
    |> where(
      [rl],
      rl.report_id == ^report_id and rl.status == :tried
    )
    |> update([rl], set: [status: :succeeded, succeeded_at: ^succeeded_at])
    |> select([rl], rl)
  end

  def record_failed(%{report_id: report_id, failed_at: failed_at, error_message: error_message}) do
    __MODULE__
    |> where(
      [rl],
      rl.report_id == ^report_id and rl.status in [:scheduled, :tried, :failed]
    )
    |> update([rl], set: [status: :failed, failed_at: ^failed_at, error_message: ^error_message])
    |> select([rl], rl)
  end

  def record_cancelled(%{report_id: report_id, cancelled_at: cancelled_at}) do
    __MODULE__
    |> where(
      [rl],
      rl.report_id == ^report_id and rl.status == :tried
    )
    |> update([rl], set: [status: :cancelled, cancelled_at: ^cancelled_at])
    |> select([rl], rl)
  end

  def record_all_cancelled(%{
        report_job_ids: report_job_ids,
        cancelled_at: cancelled_at,
        error_message: error_message
      }) do
    __MODULE__
    |> where([rl], rl.report_job_id in ^report_job_ids)
    |> where([rl], rl.status == :scheduled)
    |> update([rl],
      set: [status: :cancelled, cancelled_at: ^cancelled_at, error_message: ^error_message]
    )
    |> select([rl], rl)
  end

  def retry_failed(%{report_log_id: report_log_id}) do
    __MODULE__
    |> where(
      [rl],
      rl.id == ^report_log_id and rl.status in [:tried, :failed]
    )
    |> update([rl], set: [status: :scheduled])
    |> select([rl], rl)
  end

  def update(%__MODULE__{status: :tried} = struct, attrs) do
    struct
    |> changeset_for_update(attrs)
  end

  def fetch_by_report_job_id(report_job_id) do
    __MODULE__
    |> where([rl], rl.report_job_id == ^report_job_id)
  end

  def list() do
    __MODULE__
    |> where([rl], rl.status != :cancelled)
  end

  def list_by_report_id(report_id) do
    __MODULE__
    |> where([rl], rl.report_id == ^report_id)
    |> where([rl], rl.status != :cancelled)
  end

  def list_error() do
    __MODULE__
    |> where([rl], rl.status == :failed)
    |> or_where(
      [rl],
      rl.status == :tried and fragment("NOW() - ? > interval '10 minute'", rl.tried_at)
    )
    |> order_by([rl], desc: rl.scheduled_at)
  end

  def lasts_by_report_ids(report_ids) do
    __MODULE__
    |> where([rl], rl.report_id in ^report_ids)
    |> distinct([rl], rl.report_id)
    |> order_by([rl], desc: rl.scheduled_at)
  end

  def preload_report(query) do
    query
    |> preload(:report)
  end
end
