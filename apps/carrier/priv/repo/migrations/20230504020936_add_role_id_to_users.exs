defmodule Carrier.Repo.Migrations.AddRoleIdToUsers do
  use Carrier.Migration

  def change do
    alter table(:users) do
      add :role_id, references(:roles), null: true
    end
  end
end
