defmodule Carrier.Repo.Migrations.ChangeRoleIdOnUsersToNonNull do
  use Carrier.Migration

  def change do
    execute(
      """
        ALTER TABLE users ALTER COLUMN role_id SET NOT NULL;
      """,
      """
        ALTER TABLE users ALTER COLUMN role_id DROP NOT NULL;
      """
    )
  end
end
