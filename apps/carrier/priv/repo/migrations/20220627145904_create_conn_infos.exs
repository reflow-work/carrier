defmodule Carrier.Repo.Migrations.CreateConnInfos do
  use Carrier.Migration

  def change do
    create table(:conn_infos) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :encrypted_info, :binary, null: false

      add_tstz()
    end

    create unique_index(:conn_infos, [:org_id, :name])
  end
end
