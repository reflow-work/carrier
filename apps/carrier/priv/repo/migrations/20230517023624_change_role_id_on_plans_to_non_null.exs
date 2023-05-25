defmodule Carrier.Repo.Migrations.ChangeRoleIdOnPlansToNonNull do
  use Carrier.Migration

  def change do
    alter_nullable(:plans, :role_id, false)
  end
end
