defmodule Carrier.Repo.Migrations.CreateFeatureFlagValues do
  use Carrier.Migration

  def change do
    create table(:feature_flag_values) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :key, references(:feature_flags, column: :key, type: :string), null: false
      add :value, :boolean, null: false
    end

    create unique_index(:feature_flag_values, [:org_id, :key])
  end
end
