defmodule Carrier.Data.Source.RDB.Athena do
  @behaviour Carrier.Data.Source.RDB

  require Logger

  @impl Carrier.Data.Source.RDB
  def validate_conn(credentials) do
    case run_query(credentials, "SELECT 1") do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Carrier.Data.Source.RDB
  def param(_n) do
    "?"
  end

  # TODO: ReqAthena 는 쓰기 쉽긴 한데, error 를 걸러내기가 힘듦.
  # AWS API 를 사용하는 방식으로 바꾸거나 ReqAthena 를 수정할 필요성이 있음
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

      {:ok, %Req.Response{body: json_str}} ->
        error = json_str |> Jason.decode!()

        Logger.error(error)

        reason =
          case error do
            %{"Message" => message} ->
              {:query_error, message}

            %{"message" => message} ->
              {:invalid_conn_info, message}
          end

        {:error, reason}

      {:error, %Mint.TransportError{reason: reason}} ->
        Logger.error(inspect(reason))

        {:error, {:invalid_conn_info, reason}}

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
