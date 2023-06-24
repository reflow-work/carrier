defmodule Carrier.Repo.Migrations.AddOnboardedToOrgs do
  use Carrier.Migration

  def change do
    alter table(:orgs) do
      add :onboarded, :boolean, null: false, default: false
    end

    execute("UPDATE orgs SET onboarded = true WHERE name <> 'organization'")
  end
end
