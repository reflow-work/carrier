defmodule Carrier.Repo.Migrations.AddDatetimeFieldsToUsers do
  use Carrier.Migration

  def change do
    alter table(:users) do
      add :signed_at, :utc_datetime_usec, null: false, default: fragment("NOW()")
      add :agreed_privacy_policy_at, :utc_datetime_usec, null: true
      add :agreed_terms_of_service_at, :utc_datetime_usec, null: true
    end
  end
end
