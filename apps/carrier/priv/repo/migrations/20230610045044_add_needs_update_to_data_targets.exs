defmodule Carrier.Repo.Migrations.AddNeedsUpdateToDataTargets do
  use Carrier.Migration

  def change do
    alter table(:data_targets) do
      add :needs_update, :boolean, null: false, default: false
    end
  end
end
