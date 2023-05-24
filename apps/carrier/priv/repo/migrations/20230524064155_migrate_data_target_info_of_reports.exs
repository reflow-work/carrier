defmodule Carrier.Repo.Migrations.MigrateDataTargetInfoOfReports do
  use Carrier.Migration

  def change do
    execute("""
    UPDATE reports
      SET data_target_info =
        JSONB_BUILD_OBJECT(
          'data_target_id', data_target_info-> 'data_target_id',
          'target', 'slack',
          'params', JSONB_BUILD_OBJECT(
            'channel_id', data_target_info->'channel_id',
            'channel_name', data_target_info->'channel_name'
            )
        )
    """)
  end
end
