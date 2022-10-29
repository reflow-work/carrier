defmodule Carrier.Repo.Migrations.AddDeletedAtToConnInfosIntegrationsDataSources do
  use Carrier.Migration

  def change do
    alter table(:conn_infos) do
      add :deleted_at, :timestamptz, null: true
    end

    drop unique_index(:conn_infos, [:org_id, :name])
    create unique_index(:conn_infos, [:org_id, :name], where: "deleted_at IS NULL")

    alter table(:integrations) do
      add :deleted_at, :timestamptz, null: true
    end

    alter table(:data_sources) do
      add :deleted_at, :timestamptz, null: true
    end

    drop unique_index(:data_sources, [:org_id, :name])
    create unique_index(:data_sources, [:org_id, :name], where: "deleted_at IS NULL")
  end
end
