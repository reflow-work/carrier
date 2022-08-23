defmodule Carrier.Repo.Migrations.CreateIntegrations do
  use Carrier.Migration

  def change do
    create table(:integrations) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :service_name, :string, null: false

      add :conn_info_id, references(:conn_infos, with: [org_id: :org_id, service_name: :source]),
        null: false
    end

    create index(:integrations, [:org_id])
  end
end
