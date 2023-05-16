defmodule Carrier.Integrations.ConnValidator do
  import Carrier.Data.Source.RDB.Guard
  alias Carrier.Integrations.{ConnInfo, DataSource}
  alias Carrier.Data.Source
  alias Carrier.Repo

  def validate(source, info, opts \\ []) do
    credentials = ConnInfo.Info.to_credentials(source, info)

    do_validate(source, credentials, opts)
  end

  def do_validate(source, credentials, opts \\ [])

  def do_validate(source, credentials, opts) when is_rdb_source(source) do
    query = Source.RDB.get_module(source).validation_query()

    case Source.RDB.run_query(source, credentials, query, [], opts) do
      {:ok, _} -> :ok
      {:error, {:db_invalid_credential, message}} -> {:error, {:invalid_conn_info, message}}
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  def do_validate(:tableau, credentials, _opts) do
    case Source.Tableau.signin(credentials) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  def do_validate(_, _, _) do
    :ok
  end

  def validate_data_sources() do
    DataSource.list()
    |> DataSource.preload_conn_info()
    |> Repo.all()
    |> Enum.map(fn %DataSource{
                     id: data_source_id,
                     conn_info: %ConnInfo{source: source, info: info}
                   } ->
      try do
        {data_source_id, validate(source, info)}
      rescue
        e ->
          {data_source_id, {:error, inspect(e)}}
      end
    end)
  end
end
