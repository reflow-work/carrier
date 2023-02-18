defmodule Carrier.Repo.Migrations.CreateFeatureFlagValues do
  use Carrier.Migration

  def change do
    create table(:feature_flag_values) do
      add :org_id, references(:orgs, column: :org_id), null: false

      add :feature_flag_id, references(:feature_flags, with: [feature_flag_key: :key]),
        null: false

      add :feature_flag_key, :string, null: false
      add :value, :boolean, null: false
    end

    create unique_index(:feature_flag_values, [:org_id, :feature_flag_id])
  end
end
