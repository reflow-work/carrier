defmodule Carrier.Repo.Migrations.AddDomainToOrgs do
  use Carrier.Migration

  def change do
    alter table(:orgs) do
      add :domain, :string, null: true
    end
  end
end
