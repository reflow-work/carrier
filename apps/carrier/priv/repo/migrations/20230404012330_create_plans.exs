defmodule Carrier.Repo.Migrations.CreatePlans do
  use Carrier.Migration

  def change do
    create table(:plans) do
      add :billing_cycle, :string, null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :price, :decimal, null: false
      add :currency, :string, null: false
      add :description, :jsonb, null: false,

      add :deleted_at, :timestamptz, null: true

      add_tstz()
    end
  end
end
