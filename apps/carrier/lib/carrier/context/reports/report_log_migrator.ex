defmodule Carrier.Reports.ReportLogMigrator do
  import Ecto.Query
  alias Carrier.Reports.ReportLog
  alias Carrier.Repo

  def run() do
    # ReportLog 가 없는 Oban.Job 목록
    jobs_wo_report_log =
      Oban.Job
      |> join(:left, [j], rl in ReportLog, on: rl.report_job_id == j.id)
      |> where([j, rl], is_nil(rl.id))
      |> where([j], j.worker == "Carrier.Works.ReportJob")
      |> Repo.all()

    # 현재 status 와 맞는 ReportLog 생성
    report_logs =
      jobs_wo_report_log
      |> Enum.map(&job_to_report_log/1)

    Repo.insert_all(ReportLog, report_logs)
  end

  # Don't handle retryable, cancelled

  defp job_to_report_log(%Oban.Job{state: state} = job)
       when state in ["scheduled", "available"] do
    job
    |> default_args()
    |> Map.merge(%{
      status: :scheduled,
      created_at: job.inserted_at,
      scheduled_at: job.scheduled_at
    })
  end

  defp job_to_report_log(%Oban.Job{state: state} = job) when state in ["executing"] do
    job
    |> default_args()
    |> Map.merge(%{
      status: :tried,
      created_at: job.inserted_at,
      scheduled_at: job.scheduled_at,
      tried_at: job.attempted_at
    })
  end

  defp job_to_report_log(%Oban.Job{state: state} = job) when state in ["completed"] do
    job
    |> default_args()
    |> Map.merge(%{
      status: :succeeded,
      created_at: job.inserted_at,
      scheduled_at: job.scheduled_at,
      tried_at: job.attempted_at,
      succeeded_at: job.completed_at
    })
  end

  defp job_to_report_log(%Oban.Job{state: state} = job) when state in ["discarded"] do
    job
    |> default_args()
    |> Map.merge(%{
      status: :failed,
      created_at: job.inserted_at,
      scheduled_at: job.scheduled_at,
      tried_at: job.attempted_at,
      failed_at: job.discarded_at
    })
  end

  defp default_args(%Oban.Job{
         id: report_job_id,
         args: %{"org_id" => org_id, "report_id" => report_id}
       }) do
    %{
      org_id: org_id,
      report_id: report_id,
      report_job_id: report_job_id
    }
  end
end
