defmodule Carrier.Data.Source.RDB.Guard do
  @sources [
    :postgres,
    :mysql,
    :bigquery,
    :athena,
    :rdb_demo
  ]

  defguard is_rdb_source(source) when source in @sources
end
