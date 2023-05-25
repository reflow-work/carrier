defmodule Carrier.Repo.Migrations.ChangeCreditCardIdOfPaymentsToNullable do
  use Carrier.Migration

  def change do
    alter_nullable(:payments, :credit_card_id, true)
  end
end
