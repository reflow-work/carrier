defmodule Carrier.Repo.Migrations.AddDeletedAtToConnInfosIntegrationsDataSources do
  use Carrier.Migration

  def change do
    alter table(:conn_infos) do
      add :deleted_at, :timestamptz, null: true
    end

    alter table(:integrations) do
      add :deleted_at, :timestamptz, null: true
    end

    alter table(:data_sources) do
      add :deleted_at, :timestamptz, null: true
    end
  end
end
