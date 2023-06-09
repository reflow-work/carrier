defmodule Carrier.Repo.Migrations.ChangeTriggerTimeOfReportsToNullable do
  use Carrier.Migration

  def change do
    alter_nullable(:reports, :trigger_time, true)
  end
end
