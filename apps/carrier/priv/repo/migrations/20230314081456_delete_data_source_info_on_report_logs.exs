defmodule Carrier.Repo.Migrations.DeleteDataSourceInfoOnReportLogs do
  use Carrier.Migration

  def change do
    alter table(:report_logs) do
      remove :data_source_info
    end
  end
end
