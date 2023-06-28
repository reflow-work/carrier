defmodule Carrier.Data.Source.RDB.Guard do
  @sources [
    :postgres,
    :mysql,
    :bigquery,
    :athena
  ]

  defguard is_rdb_source(source) when source in @sources
end
