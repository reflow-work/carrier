defmodule Carrier.Repo.Migrations.AddCancelledStatusToReportLogs do
  use Carrier.Migration

  def change do
    alter table(:report_logs) do
      add :cancelled_at, :utc_datetime_usec, null: true
    end
  end
end
