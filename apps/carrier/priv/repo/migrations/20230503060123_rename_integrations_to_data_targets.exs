defmodule Carrier.Repo.Migrations.RenameIntegrationsToDataTargets do
  use Carrier.Migration

  def change do
    rename table(:integrations), to: table(:data_targets)
  end
end
