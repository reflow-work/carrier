defmodule Carrier.Repo.Migrations.AddDeletedAtToUsers do
  use Carrier.Migration

  def change do
    alter table(:users) do
      add :deleted_at, :timestamptz, null: true
    end

    drop unique_index(:users, [:email])
    create unique_index(:users, [:email], where: "deleted_at IS NULL")
  end
end
