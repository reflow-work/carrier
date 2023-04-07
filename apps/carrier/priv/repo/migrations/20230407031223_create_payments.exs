defmodule Carrier.Repo.Migrations.CreatePayments do
  use Carrier.Migration

  def change do
    create table(:payments) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :credit_card_id, references(:credit_cards), null: false
      add :amount, :decimal, null: false
      add :currency, :string, null: false
      add :status, :string, null: false
      add :confirmed_at, :timestamptz, null: true
      add :failed_at, :timestamptz, null: true
      add :provider, :string, null: true
      add :provider_key, :json, null: true
      add :payload, :jsonb, null: true

      add_tstz()
    end
  end
end
