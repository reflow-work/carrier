defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema
  alias Carrier.Reports.{IntegrationInfo, DataSourceInfo}

  schema "report_logs" do
    field :org_id, :integer
    field :report_id, :integer

    field :status, Ecto.Enum,
      values: [:scheduled, :tried, :succeeded, :failed],
      default: :scheduled

    field :created_at, :utc_datetime_usec
    field :scheduled_at, :utc_datetime_usec
    field :tried_at, :utc_datetime_usec
    field :succeeded_at, :utc_datetime_usec
    field :payload, :map
    field :error_message, :string

    embeds_one :integration_info, IntegrationInfo, on_replace: :delete
    embeds_one :data_source_info, DataSourceInfo, on_replace: :delete
  end

  @required_for_record_scheduled [:org_id, :report_id, :created_at, :scheduled_at]
  defp changeset_for_record_scheduled(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_record_scheduled)
    |> validate_required(@required_for_record_scheduled)
  end

  @required_for_record_succeeded [:succeeded_at]
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

  def record_scheduled(%{
        org_id: org_id,
        report_id: report_id,
        created_at: created_at,
        scheduled_at: scheduled_at
      }) do
    %__MODULE__{}
    |> changeset_for_record_scheduled(%{
      org_id: org_id,
      report_id: report_id,
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

  def record_succeeded(%__MODULE__{} = struct, %{
        succeeded_at: succeeded_at
      }) do
    struct
    |> changeset_for_record_succeeded(%{
      succeeded_at: succeeded_at
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
