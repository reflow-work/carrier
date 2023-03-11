defmodule Carrier.Repo.Migrations.MigrateSourceInDataSourceInfoOfReports do
  use Carrier.Migration

  def change do
    execute("""
    UPDATE reports r
      SET data_source_info['source'] = to_jsonb(ds.source)
      FROM data_sources ds
      WHERE ds.id = (r.data_source_info['data_source_id'])::INT8;
    """)
  end
end
