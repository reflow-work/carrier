defmodule Carrier.Repo.Migrations.AddCancelledAtToSubscriptions do
  use Carrier.Migration

  def change do
    alter table(:subscriptions) do
      add :cancelled_at, :utc_datetime
      add :deleted_at, :utc_datetime
    end
  end
end
