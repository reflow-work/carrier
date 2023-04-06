defmodule Carrier.Repo.Migrations.CreateCreditCards do
  use Carrier.Migration

  def change do
    create table(:credit_cards) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :provider, :string, null: false
      add :billing_key, :string, null: false
      add :customer_key, :string, null: false
      add :card_company, :string, null: false
      add :card_number, :string, null: false
      add :deleted_at, :timestamptz, null: true

      add_tstz()
    end

    create unique_index(:credit_cards, [:org_id], where: "deleted_at IS NULL")
  end
end
