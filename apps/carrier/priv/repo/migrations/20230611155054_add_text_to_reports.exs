defmodule Carrier.Repo.Migrations.AddTextToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :text, :text, null: true
    end
  end
end
