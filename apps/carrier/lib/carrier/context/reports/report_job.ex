defmodule Carrier.Reports.ReportJob do
  use Carrier.Schema
  alias Carrier.Core.ModuleHelper

  schema "oban_jobs" do
    field :worker, :string

    embeds_one :args, Args do
      field :org_id, :id
    end

    field :state, Ecto.Enum,
      values: [:available, :scheduled, :executing, :retryable, :completed, :discarded, :cancelled]

    field :max_attempts, :integer
    field :discarded_at, :utc_datetime_usec
    field :cancelled_at, :utc_datetime_usec
  end

  def list_by_org_id(query \\ __MODULE__, org_id) do
    query
    |> query_report_job()
    |> where([rj], rj.args["org_id"] == ^org_id)
  end

  def cancel_excutable(%{org_id: org_id, cancelled_at: cancelled_at}) do
    __MODULE__
    |> query_report_job()
    |> where([rj], rj.args["org_id"] == ^org_id)
    |> where([rj], rj.state in [:executing, :available, :scheduled, :retryable])
    |> update([rj], set: [state: :cancelled, cancelled_at: ^cancelled_at])
    |> select([rj], rj)
  end

  def retry_discarded(%{report_job_id: report_job_id}) do
    __MODULE__
    |> query_report_job()
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

  defp query_report_job(query) do
    worker = Carrier.Works.ReportJob |> ModuleHelper.to_string()

    query
    |> where([rj], rj.worker == ^worker)
  end
end
