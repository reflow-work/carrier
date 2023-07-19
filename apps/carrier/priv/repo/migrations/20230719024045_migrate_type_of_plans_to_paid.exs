defmodule Carrier.Repo.Migrations.MigrateTypeOfPlansToPaid do
  use Carrier.Migration

  def change do
    execute("UPDATE plans SET type = 'paid' WHERE type in ('basic', 'pro')")
  end
end
