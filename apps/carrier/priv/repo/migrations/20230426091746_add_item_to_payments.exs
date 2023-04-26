defmodule Carrier.Repo.Migrations.AddItemToPayments do
  use Carrier.Migration

  def change do
    alter table(:payments) do
      add :item, :string, null: true
    end
  end
end
