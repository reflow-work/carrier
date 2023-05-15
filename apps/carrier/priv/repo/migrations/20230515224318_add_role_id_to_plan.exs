defmodule Carrier.Repo.Migrations.AddRoleIdToPlan do
  use Carrier.Migration

  def change do
    alter table(:plans) do
      add :role_id, references(:roles), null: true
    end
  end
end
