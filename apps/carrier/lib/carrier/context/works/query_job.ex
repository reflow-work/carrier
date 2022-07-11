defmodule Carrier.Works.QueryJob do
  use Oban.Worker, queue: :default
  require Logger
  alias Carrier.Secrets
  alias Carrier.Secrets.ConnInfo
  alias Carrier.TenantRepo
  alias Carrier.Dynamic.PostgresRepo
  alias Carrier.External.SlackWebhook
  alias TableRex.Table

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
         "datetime" => datetime_str,
         "slack_webhook_url" => slack_webhook_url
       }) do
    TenantRepo.put_org_id(org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %ConnInfo{} = conn_info} = Secrets.fetch_conn_info(conn_info_id),
         {:ok, %{header: header, rows: rows}} <- run_query(conn_info, datetime),
         {:ok, message} <- make_message(%{header: header, rows: rows}),
         {:ok, _} <- SlackWebhook.send_message(slack_webhook_url, message) do
      :ok
    end
  end

  defp run_query(%ConnInfo{type: type, info: info}, datetime) do
    case type do
      "postgres" ->
        credentials =
          info
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.new()

        query =
          "SELECT *, $1::timestamp FROM unnest(ARRAY[1, 2]) AS count, unnest(ARRAY[1, 2]) AS value"

        PostgresRepo.with_dynamic_repo(credentials, fn ->
          %{columns: columns, rows: rows} =
            Ecto.Adapters.SQL.query!(PostgresRepo, query, [
              datetime
            ])

          {:ok, %{header: columns, rows: rows}}
        end)
    end
  end

  defp make_message(%{header: header, rows: rows}) do
    table_str =
      Table.new(rows, header)
      |> Table.render!()

    {:ok, table_str}
  end

  defp schedule_next(%Oban.Job{
         args:
           %{
             "scheduled_at" => scheduled_at_str,
             "datetime" => datetime_str
           } = args,
         meta: meta
       }) do
    {:ok, scheduled_at, _} = scheduled_at_str |> DateTime.from_iso8601()
    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    new_scheduled_at = scheduled_at |> DateTime.add(10, :second)
    new_datetime = datetime |> DateTime.add(10, :second)

    Logger.debug("next job is scheduled_at #{inspect(new_scheduled_at)}")

    %{args | "scheduled_at" => new_scheduled_at, "datetime" => new_datetime}
    |> new(meta: meta, scheduled_at: new_scheduled_at)
    |> then(&Oban.insert(CarrierWorker.Oban, &1))
  end
end
