defmodule Carrier.Repo.Migrations.MigrateIntegrationIdOfDataTargetInfoOfReportsToDataTargetId do
  use Carrier.Migration

  def change do
    execute(
      """
      UPDATE reports
        SET data_target_info = data_target_info - 'integration_id' || jsonb_build_object('data_target_id', data_target_info->'integration_id')
        WHERE data_target_info ? 'integration_id'
      """,
      """
      UPDATE reports
        SET data_target_info = data_target_info - 'data_target_id' || jsonb_build_object('integration_id', data_target_info->'data_target_id')
        WHERE data_target_info ? 'data_target_id'
      """
    )
  end
end
