defmodule Carrier.Repo.Migrations.AddUserIdToReports do
  use Carrier.Migration

  def change do
    create unique_index(:users, [:id, :org_id])

    alter table(:reports) do
      add :user_id, references(:users, with: [org_id: :org_id]), null: true
    end
  end
end
