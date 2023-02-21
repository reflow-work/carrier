defmodule Carrier.Repo.Migrations.AddDefaultValueToFeatureFlag do
  use Carrier.Migration

  def change do
    alter table(:feature_flags) do
      add :value, :boolean, null: false, default: false
    end
  end
end
