defmodule Carrier.Repo.Migrations.ChangeReportLogsOrgIdReportIdStatusIndex do
  use Carrier.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    drop index(:report_logs, [:org_id, :report_id, :status])

    create index(:report_logs, [:org_id, :report_id, :status],
             where: "status NOT IN ('succeeded', 'cancelled')",
             concurrently: true
           )
  end
end
