defmodule Carrier.Repo.Migrations.MigrateTimezoneOfReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :timezone, :string, null: true
    end

    execute("""
      UPDATE reports
        SET timezone = data_source_info['timezone']
        WHERE timezone IS NULL
    """)

    alter table(:reports) do
      modify :timezone, :string, null: false
    end
  end
end
