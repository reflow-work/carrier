defmodule Carrier.Repo.Migrations.AddOnboardingFieldsToOrg do
  use Carrier.Migration

  def change do
    alter table(:orgs) do
      add :industry, :string, null: true
      add :employee_count, :string, null: true
    end
  end
end
