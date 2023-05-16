defmodule Carrier.Data.Source.RDB.Athena do
  @behaviour Carrier.Data.Source.RDB

  require Logger

  @impl Carrier.Data.Source.RDB
  def validation_query() do
    "SELECT 1"
  end

  @impl Carrier.Data.Source.RDB
  def param(_n) do
    "?"
  end

  @impl Carrier.Data.Source.RDB
  def run_query(
        %{
          access_key_id: _access_key_id,
          secret_access_key: _secret_access_key,
          region: _region,
          workgroup: _workgroup,
          database: _database
        } = credential,
        sql,
        sql_params \\ [],
        _opts \\ []
      ) do
    with {:ok, %Req.Response{status: 200, body: %ReqAthena.Result{} = result}} <-
           request_query(credential, sql, sql_params) do
      {:ok, result}
    else
      {:ok,
       %Req.Response{
         body: %{
           "QueryExecution" => %{"Status" => %{"AthenaError" => %{"ErrorMessage" => message}}}
         }
       }} ->
        Logger.error(inspect(message))

        {:error, {:query_error, message}}

      {:ok, %Req.Response{body: %{"error" => %{"message" => message}}}} ->
        Logger.error(inspect(message))

        {:error, {:query_error, message}}

      {:error, reason} ->
        Logger.error(inspect(reason))

        {:error, reason}
    end
  end

  defp request_query(credential, sql, sql_params) do
    Req.new()
    |> ReqAthena.attach(credential |> Keyword.new())
    |> Req.post(athena: {sql, sql_params})
  end
end
