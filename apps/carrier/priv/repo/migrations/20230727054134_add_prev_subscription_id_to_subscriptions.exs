defmodule Carrier.Repo.Migrations.AddPrevSubscriptionIdToSubscriptions do
  use Carrier.Migration

  def change do
    alter table(:subscriptions) do
      add :prev_subscription_id, references(:subscriptions), null: true
    end
  end
end
