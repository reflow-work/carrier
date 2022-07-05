defmodule Carrier.Works.QueryJob do
  use Oban.Worker, queue: :default
  require Logger
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo
  alias Carrier.External.SlackWebhook

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = job) do
    with :ok <- do_perform(args),
         {:ok, _next_job} <- schedule_next(job) do
      :ok
    end

    :ok
  end

  defp do_perform(%{
         "org_id" => org_id,
         "conn_info_id" => conn_info_id,
         "slack_webhook_url" => slack_webhook_url
       }) do
    TenantRepo.put_org_id(org_id)

    with {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{header: header, rows: rows}} <- run_query(conn_info),
         {:ok, message} <- make_message(%{header: header, rows: rows}),
         {:ok, _} <- SlackWebhook.send_message(slack_webhook_url, message) do
      :ok
    end
  end

  defp run_query(%ConnInfo{type: type, info: info}) do
    case type do
      "postgres" ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        PostgresRepo.with_dynamic_repo(credentials, fn ->
          %{columns: columns, rows: rows} = Ecto.Adapters.SQL.query!(PostgresRepo, "SELECT 1")

          {:ok, %{header: columns, rows: rows}}
        end)
    end
  end

  defp make_message(%{header: header, rows: rows}) do
    {:ok, inspect([header, rows])}
  end

  defp schedule_next(%Oban.Job{args: %{"scheduled_at" => scheduled_at_str} = args, meta: meta}) do
    {:ok, scheduled_at, _} = scheduled_at_str |> DateTime.from_iso8601()

    new_scheduled_at = scheduled_at |> DateTime.add(10, :second)

    Logger.debug("next job is scheduled_at #{inspect(new_scheduled_at)}")

    %{args | "scheduled_at" => new_scheduled_at}
    |> new(meta: meta, scheduled_at: new_scheduled_at)
    |> then(&Oban.insert(CarrierWorker.Oban, &1))
  end
end
