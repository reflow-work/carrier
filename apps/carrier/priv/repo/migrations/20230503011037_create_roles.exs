defmodule Carrier.Repo.Migrations.CreateRoles do
  use Carrier.Migration

  def change do
    create table(:roles) do
      add :name, :string, null: false
      add :permissions, {:array, :string}, null: false
      add :deleted_at, :timestamptz, null: true

      add_tstz()
    end
  end
end
