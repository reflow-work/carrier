defmodule Carrier.Repo.Migrations.DeleteIntegrationInfoOnReportLogs do
  use Carrier.Migration

  def change do
    alter table(:report_logs) do
      remove :integration_info
    end
  end
end
