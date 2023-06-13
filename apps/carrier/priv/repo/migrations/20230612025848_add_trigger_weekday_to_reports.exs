defmodule Carrier.Repo.Migrations.AddTriggerWeekdayToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :trigger_weekday, :integer, null: true
    end
  end
end
