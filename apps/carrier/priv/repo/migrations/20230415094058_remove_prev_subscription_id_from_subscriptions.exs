defmodule Carrier.Repo.Migrations.RemovePrevSubscriptionIdFromSubscriptions do
  use Carrier.Migration

  def change do
    alter table(:subscriptions) do
      remove :prev_subscription_id
    end
  end
end
