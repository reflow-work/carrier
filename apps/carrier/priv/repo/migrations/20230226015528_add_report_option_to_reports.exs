defmodule Carrier.Repo.Migrations.AddReportOptionToReports do
  use Carrier.Migration

  def change do
    alter table(:reports) do
      add :report_option, :map, null: false, default: %{elements: [:chart]}
    end
  end
end
