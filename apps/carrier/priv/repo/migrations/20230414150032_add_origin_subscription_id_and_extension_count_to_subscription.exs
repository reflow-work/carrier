defmodule Carrier.Repo.Migrations.AddOriginSubscriptionIdAndExtensionCountToSubscription do
  use Carrier.Migration

  def change do
    alter table(:subscriptions) do
      add :origin_subscription_id, references(:subscriptions), null: true
      add :extension_count, :integer, null: false, default: 0
    end
  end
end
