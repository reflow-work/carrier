defmodule Carrier.Secrets.ConnValidator do
  alias Carrier.Secrets.{ConnInfo, DataSource}
  alias Carrier.Data.Source
  alias Carrier.Repo

  def validate(source, info, opts \\ []) do
    credentials = ConnInfo.Info.to_credentials(source, info)

    do_validate(source, credentials, opts)
  end

  def do_validate(source, credentials, opts \\ [])

  def do_validate(source, credentials, opts) when source in [:mysql, :postgres, :bigquery] do
    query = Source.get_module(source).validation_query()

    case Source.run_query(source, credentials, query, [], opts) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :invalid_conn_info}
    end
  end

  def do_validate(_, _, _) do
    :ok
  end

  def validate_data_sources() do
    DataSource
    |> DataSource.preload_conn_info()
    |> Repo.all()
    |> Enum.map(fn %DataSource{
                     id: data_source_id,
                     conn_info: %ConnInfo{source: source, info: info}
                   } ->
      {data_source_id, validate(source, info)}
    end)
  end
end
