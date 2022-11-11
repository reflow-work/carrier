defmodule Carrier.Repo.Migrations.AddPositionToUsers do
  use Carrier.Migration

  def change do
    alter table(:users) do
      add :position, :string, null: true
    end
  end
end
