defmodule Carrier.Integrations.ConnValidator do
  alias Carrier.Integrations.{ConnInfo, DataSource}
  alias Carrier.Data
  alias Carrier.Repo

  def validate(source, info, type, opts \\ []) do
    credentials = ConnInfo.Info.to_credentials(source, info)

    Data.validate_conn(source, credentials, type, opts)
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
        {data_source_id, validate(source, info, :source)}
      rescue
        e ->
          {data_source_id, {:error, inspect(e)}}
      end
    end)
  end
end
