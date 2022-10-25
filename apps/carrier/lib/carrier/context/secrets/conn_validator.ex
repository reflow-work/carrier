defmodule Carrier.Secrets.ConnValidator do
  require Logger
  alias Carrier.Secrets.ConnInfo
  alias Carrier.Dynamic.{PostgresRepo, MySQLRepo}

  def validate(source, info) do
    module = ConnInfo.Info.get_module_from_source(source)
    struct = struct(module, info)

    do_validate(struct)
  end

  def do_validate(%ConnInfo.Postgres{} = struct) do
    %Postgrex.Result{} =
      struct
      |> Map.from_struct()
      |> Keyword.new()
      |> PostgresRepo.with_dynamic_repo(fn ->
        PostgresRepo.query!("SELECT 1")
      end)

    :ok
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :invalid_conn_info}
  end

  def do_validate(%ConnInfo.MySQL{} = struct) do
    %MyXQL.Result{} =
      struct
      |> Map.from_struct()
      |> Keyword.new()
      |> MySQLRepo.with_dynamic_repo(fn ->
        MySQLRepo.query!("SELECT 1")
      end)

    :ok
  rescue
    e ->
      Logger.error(inspect(e))

      {:error, :invalid_conn_info}
  end

  def do_validate(_) do
    :ok
  end
end
