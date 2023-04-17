defmodule Carrier.Repo.Migrations.AddOriginalPrice do
  use Carrier.Migration

  def change do
    alter table(:plans) do
      add(:original_price, :decimal, null: true)
    end
  end
end
