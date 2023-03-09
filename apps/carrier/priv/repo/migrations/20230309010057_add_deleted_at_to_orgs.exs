defmodule Carrier.Repo.Migrations.AddDeletedAtToOrgs do
  use Carrier.Migration

  def change do
    alter table(:orgs) do
      add :deleted_at, :timestamptz, null: true
    end
  end
end
