defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema
  alias Carrier.Reports.{Report, IntegrationInfo, DataSourceInfo}

  schema "report_logs" do
    belongs_to :report, Report

    field :org_id, :integer
    field :report_job_id, :integer

    field :status, Ecto.Enum,
      values: [:scheduled, :tried, :succeeded, :failed],
      default: :scheduled

    field :created_at, :utc_datetime_usec
    field :scheduled_at, :utc_datetime_usec
    field :tried_at, :utc_datetime_usec
    field :succeeded_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec
    field :payload, {:array, :any}
    field :error_message, :string

    embeds_one :integration_info, IntegrationInfo, on_replace: :delete
    embeds_one :data_source_info, DataSourceInfo, on_replace: :delete
  end

  @required_for_record_scheduled [:org_id, :report_id, :report_job_id, :created_at, :scheduled_at]
  defp changeset_for_record_scheduled(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_record_scheduled)
    |> validate_required(@required_for_record_scheduled)
  end

  @optional_for_update [:payload]
  defp changeset_for_update(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @optional_for_update)
    |> cast_embed(:integration_info, with: &IntegrationInfo.changeset_for_create/2)
    |> cast_embed(:data_source_info, with: &DataSourceInfo.changeset_for_create/2)
  end

  def record_scheduled(%{
        org_id: org_id,
        report_id: report_id,
        report_job_id: report_job_id,
        created_at: created_at,
        scheduled_at: scheduled_at
      }) do
    %__MODULE__{}
    |> changeset_for_record_scheduled(%{
      org_id: org_id,
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
      rl.report_id == ^report_id and rl.status == :scheduled
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
      rl.report_id == ^report_id and rl.status == :tried
    )
    |> update([rl], set: [status: :failed, failed_at: ^failed_at, error_message: ^error_message])
    |> select([rl], rl)
  end

  def update(%__MODULE__{status: :tried} = struct, attrs) do
    struct
    |> changeset_for_update(attrs)
  end

  def list() do
    __MODULE__
    |> order_by([rl], desc: rl.scheduled_at)
  end

  def preload_report(query) do
    query
    |> preload(:report)
  end
end
