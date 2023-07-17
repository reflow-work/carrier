defmodule Carrier.Repo.Migrations.AddTriggerMinuteToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :trigger_minute, :integer, null: false, default: 0
    end
  end
end
