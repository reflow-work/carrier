defmodule Carrier.Works.ReportJob do
  use Oban.Worker, queue: :default
  require Logger
  alias Carrier.Data.QueryData
  alias Carrier.Secrets
  alias Carrier.Secrets.Integration
  alias Carrier.Noti
  alias Carrier.TenantRepo
  alias Carrier.External.Aws
  alias Carrier.External.Slack
  alias Carrier.Core.Traversable

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = job) do
    with :ok <- do_perform(args),
         {:ok, _next_job} <- schedule_next(job) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to send report: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp do_perform(%{
         "org_id" => org_id,
         "report_id" => report_id,
         "name" => _name,
         "datetime" => datetime_str,
         "integration_info" => %{
           "integration_id" => integration_id,
           "channel_id" => channel_id
         },
         "data_source_info" => %{
           "data_source_id" => data_source_id,
           "sql_template" => sql_template,
           "timezone" => timezone,
           "period" => period,
           "window_size" => window_size,
           "comparing_period" => comparing_period,
           "columns" => _columns
         }
       }) do
    TenantRepo.put_org_id(org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %Integration{} = integration} <- Secrets.fetch_integration(integration_id),
         {:ok, raw_data} <-
           QueryData.query(%{
             org_id: org_id,
             data_source_id: data_source_id,
             sql_template: sql_template,
             datetime: datetime,
             timezone: timezone,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period
           }),
         parsed_data = QueryData.refine_data_based_on_columns(raw_data),
         {:ok, %{"body" => %{"imgUrls" => img_urls}}, _} <-
           Aws.save_chart_img(%{
             data: parsed_data,
             orgId: org_id,
             reportId: report_id
           }),
         slack_args = Slack.build_post_message_args(parsed_data, img_urls),
         {:ok, _} <-
           slack_args
           |> Enum.map(
             &Noti.send_report_to_slack(
               channel_id,
               &1,
               integration.conn_info.info["bot_token"]
             )
           )
           |> Traversable.traverse() do
      :ok
    end
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

    new_scheduled_at = scheduled_at |> Timex.shift(days: 1)
    new_datetime = datetime |> Timex.shift(days: 1)

    Logger.debug("next job is scheduled_at #{inspect(new_scheduled_at)}")

    %{args | "scheduled_at" => new_scheduled_at, "datetime" => new_datetime}
    |> new(meta: meta, scheduled_at: new_scheduled_at)
    |> then(&Oban.insert(CarrierWorker.Oban, &1))
  end
end
