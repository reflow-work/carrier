defmodule Carrier.Repo.Migrations.CreateDataSources do
  use Carrier.Migration

  def change do
    create table(:data_sources) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :name, :string, null: false
      add :source, :string, null: false

      add :conn_info_id, references(:conn_infos, with: [org_id: :org_id, source: :source]),
        null: false
    end

    create unique_index(:data_sources, [:org_id, :name])
  end
end
