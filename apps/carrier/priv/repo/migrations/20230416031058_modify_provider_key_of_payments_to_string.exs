defmodule Carrier.Repo.Migrations.ModifyProviderKeyOfPaymentsToString do
  use Carrier.Migration

  def change do
    alter table(:payments) do
      modify :provider_key, :string
    end
  end
end
