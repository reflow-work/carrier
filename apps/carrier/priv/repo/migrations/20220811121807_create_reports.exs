defmodule Carrier.Repo.Migrations.CreateReports do
  use Carrier.Migration

  def change do
    create table(:reports) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :name, :string, null: false
      add :deleted_at, :timestamptz, null: true

      add_tstz()
    end

    create index(:reports, [:org_id, :created_at], where: "deleted_at IS NOT NULL")
  end
end
