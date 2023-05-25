defmodule Carrier.Repo.Migrations.AddIntervalToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :interval, :string, null: true
    end

    execute("UPDATE reports SET interval = 'daily'")

    alter_nullable(:reports, :interval, false)
  end
end
