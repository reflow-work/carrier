defmodule Carrier.Repo.Migrations.AddOnboardedToOrgs do
  use Carrier.Migration

  def change do
    alter table(:orgs) do
      add :onboarded, :boolean, null: false, default: false
    end
  end
end
