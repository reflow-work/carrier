defmodule Carrier.Reports.ReportJob do
  use Carrier.Schema

  schema "oban_jobs" do
    embeds_one :args, Args do
      field :org_id, :id
    end

    field :state, Ecto.Enum,
      values: [:available, :scheduled, :executing, :retryable, :completed, :discarded, :cancelled]

    field :max_attempts, :integer
    field :discarded_at, :utc_datetime_usec
  end

  def list_by_org_id(query \\ __MODULE__, org_id) do
    query
    |> where([rj], rj.args["org_id"] == ^org_id)
  end

  def retry_discarded(%{report_job_id: report_job_id}) do
    __MODULE__
    |> where(
      [rj],
      rj.id == ^report_job_id and rj.state == :discarded
    )
    |> update([rj],
      set: [state: :scheduled, discarded_at: nil],
      inc: [max_attempts: 1]
    )
    |> select([rj], rj)
  end
end
