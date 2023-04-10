defmodule Carrier.Repo.Migrations.CreateSubscriptions do
  use Carrier.Migration

  def change do
    create table(:subscriptions) do
      add :org_id, references(:orgs, column: :org_id), null: false
      add :plan_id, references(:plans), null: false
      add :payment_id, references(:payments), null: true
      add :prev_subscription_id, references(:subscriptions), null: true

      add :start_on, :utc_datetime_usec, null: false
      add :end_on, :utc_datetime_usec, null: false
      add :status, :string, null: false

      add :activated_at, :utc_datetime_usec, null: true
      add :expired_at, :utc_datetime_usec, null: true

      add_tstz()
    end

    create unique_index(:subscriptions, [:org_id],
             where: "status = 'pending'",
             name: :subscriptions_org_id_pending
           )

    create unique_index(:subscriptions, [:org_id],
             where: "status = 'active'",
             name: :subscriptions_org_id_active
           )
  end
end
