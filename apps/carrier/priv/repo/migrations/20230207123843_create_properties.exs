defmodule Carrier.Repo.Migrations.CreateProperties do
  use Carrier.Migration

  def change do
    create table(:properties, primary_key: false) do
      add :key, :string, primary_key: true
      add :type, :string, null: false
      add :integer_value, :int, null: true
      add :string_value, :string, null: true
      add :boolean_value, :bool, null: true
      add :decimal_value, :decimal, null: true
      add :datetime_value, :timestamp, null: true
      add :list_value, :jsonb, null: true
      add :map_value, :jsonb, null: true
    end
  end
end
