defmodule Carrier.Secrets.ConnValidator do
  require Logger
  alias Carrier.Secrets.{ConnInfo, DataSource}
  alias Carrier.Dynamic.{PostgresRepo, MySQLRepo}
  alias Carrier.Repo

  def validate(source, info, opts \\ []) do
    struct = ConnInfo.Info.get_struct(source, info)

    do_validate(struct, opts)
  end

  def do_validate(struct, opts \\ [])

  def do_validate(%ConnInfo.Postgres{} = struct, opts) do
    %Postgrex.Result{} =
      struct
      |> Map.from_struct()
      |> Keyword.new()
      |> PostgresRepo.with_dynamic_repo(opts, fn ->
        PostgresRepo.query!("SELECT 1")
      end)

    :ok
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :invalid_conn_info}
  end

  def do_validate(%ConnInfo.MySQL{} = struct, opts) do
    %MyXQL.Result{} =
      struct
      |> Map.from_struct()
      |> Keyword.new()
      |> MySQLRepo.with_dynamic_repo(opts, fn ->
        MySQLRepo.query!("SELECT 1")
      end)

    :ok
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :invalid_conn_info}
  end

  def do_validate(_, _) do
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
