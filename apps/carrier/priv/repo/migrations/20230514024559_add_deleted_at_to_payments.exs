defmodule Carrier.Repo.Migrations.AddDeletedAtToPayments do
  use Carrier.Migration

  def change do
    alter table(:payments) do
      add :deleted_at, :timestamptz
    end
  end
end
