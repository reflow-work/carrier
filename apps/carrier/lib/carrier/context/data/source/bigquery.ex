defmodule Carrier.Data.Source.BigQuery do
  @behaviour Carrier.Data.Source.RDB

  require Logger

  @impl Carrier.Data.Source.RDB
  def param(_n) do
    "?"
  end

  @impl Carrier.Data.Source.RDB
  def run_query(
        %{project_id: project_id, credentials_json: credentials_json} = _credential,
        sql,
        sql_params \\ []
      ) do
    with {:ok, _pid} <- start_credential_process(project_id, credentials_json),
         {:ok, %{body: %ReqBigQuery.Result{} = result}} <-
           request_query(project_id, sql, sql_params) do
      {:ok, result}
    else
      {:error, reason} ->
        Logger.error(inspect(reason))

        {:error, reason}
    end
  end

  defp start_credential_process(project_id, credentials_json) do
    name = credential_process_name(project_id)
    source = {:service_account, credentials_json |> Jason.decode!(), []}

    opts = [name: name, source: source, http_client: &Req.request/1]

    case DynamicSupervisor.start_child(Carrier.GothSupervisor, {Goth, opts}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp credential_process_name(project_id) do
    {Carrier.Goth, project_id}
  end

  defp request_query(project_id, sql, sql_params) do
    Req.new()
    |> ReqBigQuery.attach(goth: credential_process_name(project_id), project_id: project_id)
    |> Req.post(bigquery: {sql, sql_params})
  end
end
