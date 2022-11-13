defmodule Carrier.Repo.Migrations.CreateReportInfos do
  use Carrier.Migration

  def change do
    create table(:report_infos) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :deleted_at, :timestamptz, null: true

      add_tstz()
    end

    create index(:report_infos, [:org_id, :created_at], where: "deleted_at IS NOT NULL")
  end
end
