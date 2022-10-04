defmodule Carrier.Repo.Migrations.CreateReportLogs do
  use Carrier.Migration

  def change do
    create table(:report_logs) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :report_id, :integer, null: false
      add :status, :string, null: false
      add :created_at, :timestamptz, null: false
      add :scheduled_at, :timestamptz, null: false
      add :tried_at, :timestamptz, null: true
      add :succeeded_at, :timestamptz, null: true
      add :failed_at, :timestamptz, null: true
      add :payload, :jsonb, null: true
      add :error_message, :string, null: true
      add :integration_info, :jsonb, null: true
      add :data_source_info, :jsonb, null: true
    end

    create index(:report_logs, [:org_id, "id DESC"])

    create unique_index(:report_logs, [:org_id, :report_id, :status],
             where: "status <> 'succeeded'"
           )
  end
end
