defmodule Carrier.Reports.ReportInfoMigrator do
  import Ecto.Changeset
  alias Carrier.Reports.{Report, ReportInfo, ReportLog}
  alias Carrier.Repo

  def run() do
    reports = Report |> Repo.all()

    report_id_report_info_id_map =
      reports
      |> Enum.map(fn %Report{org_id: org_id, deleted_at: deleted_at} = report ->
        {:ok, report_info} =
          changeset_for_create_report_info(%{org_id: org_id, deleted_at: deleted_at})
          |> Repo.insert()

        {:ok, _updated_report} =
          report
          |> changeset_for_update_report(%{report_info_id: report_info.id})
          |> Repo.update()

        {report.id, report_info.id}
      end)
      |> Map.new()

    report_logs = ReportLog |> Repo.all()

    report_logs
    |> Enum.map(fn %ReportLog{report_id: report_id} = report_log ->
      report_info_id = Map.get(report_id_report_info_id_map, report_id)

      report_log
      |> changeset_for_update_report_log(%{report_info_id: report_info_id})
      |> Repo.update()
    end)
  end

  defp changeset_for_create_report_info(attrs) do
    %ReportInfo{}
    |> cast(attrs, [:org_id, :deleted_at])
    |> validate_required([:org_id])
  end

  defp changeset_for_update_report(%Report{} = report, attrs) do
    report
    |> cast(attrs, [:report_info_id])
    |> validate_required([:report_info_id])
  end

  defp changeset_for_update_report_log(%ReportLog{} = report_log, attrs) do
    report_log
    |> cast(attrs, [:report_info_id])
    |> validate_required([:report_info_id])
  end
end
