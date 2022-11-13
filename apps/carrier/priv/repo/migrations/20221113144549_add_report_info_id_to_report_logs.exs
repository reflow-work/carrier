defmodule Carrier.Repo.Migrations.AddReportInfoIdToReportLogs do
  use Carrier.Migration

  def change do
    alter table(:report_logs) do
      add :report_info_id, :integer, null: true
    end
  end
end
