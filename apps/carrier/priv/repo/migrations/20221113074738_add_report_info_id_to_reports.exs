defmodule Carrier.Repo.Migrations.AddReportInfoIdToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :report_info_id, :id, null: true
    end

    create unique_index(:reports, [:org_id, :report_info_id, :created_at])
    drop index(:reports, [:org_id, :created_at])
  end
end
