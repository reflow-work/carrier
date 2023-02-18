defmodule Carrier.Repo.Migrations.CreateFeatureFlags do
  use Carrier.Migration

  def change do
    create table(:feature_flags) do
      add :key, :string, null: false
      add :description, :string, null: false
      add_tstz()
      add :deleted_at, :timestamptz, null: true
    end

    create unique_index(:feature_flags, [:key])
    create unique_index(:feature_flags, [:id, :key])
  end
end
