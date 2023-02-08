defmodule Carrier.Repo.Migrations.CreateProperties do
  use Carrier.Migration

  def change do
    create table(:properties, primary_key: false) do
      add :key, :string, primary_key: true
      add :type, :string
      add :value, :jsonb
    end
  end
end
