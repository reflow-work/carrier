defmodule Carrier.Repo.Migrations.CreateWebhooks do
  use Carrier.Migration

  def change do
    create table(:webhooks) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :data_source_id, references(:data_sources), null: false
      add :key, :string, null: false
    end

    create unique_index(:webhooks, [:key])
  end
end
