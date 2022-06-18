defmodule Carrier.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def change do
    create table(:orgs, primary_key: false) do
      add :org_id, :bigserial, primary_key: true
      add :name, :string, null: false
    end
  end
end
