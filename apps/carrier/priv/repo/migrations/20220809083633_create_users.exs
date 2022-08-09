defmodule Carrier.Repo.Migrations.CreateUsers do
  use Carrier.Migration

  def change do
    create table(:users) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :email, :string, null: false
    end

    create unique_index(:users, [:email])
  end
end
