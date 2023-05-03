defmodule Carrier.Repo.Migrations.RenameIntegrationInfoOfReportsToDataTargetInfo do
  use Carrier.Migration

  def change do
    rename table(:reports), :integration_info, to: :data_target_info
  end
end
