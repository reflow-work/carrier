defmodule Carrier.Repo.Migrations.ChangeRoleIdOnPlansToNonNull do
  use Carrier.Migration

  def change do
    execute(
      """
        ALTER TABLE plans ALTER COLUMN role_id SET NOT NULL;
      """,
      """
        ALTER TABLE plans ALTER COLUMN role_id DROP NOT NULL;
      """
    )
  end
end
