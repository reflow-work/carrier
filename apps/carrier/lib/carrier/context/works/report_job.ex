defmodule Carrier.Works.ReportJob do
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger
  alias Carrier.Data.QueryData
  alias Carrier.Secrets
  alias Carrier.Secrets.Integration
  alias Carrier.Reports
  alias Carrier.Reports.Report
  alias Carrier.Noti
  alias Carrier.TenantRepo
  alias Carrier.External.Aws
  alias Carrier.External.Slack
  alias Carrier.Core.{Traversable, DateTimeHelper}

  @impl Oban.Worker
  def perform(
        %Oban.Job{
          args: %{"org_id" => org_id, "report_id" => report_id, "datetime" => datetime_str}
        } = job
      ) do
    TenantRepo.put_org_id(org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %Report{} = report} <- Reports.fetch_report(report_id),
         :ok <- do_perform(%{report: report, datetime: datetime}),
         {:ok, _next_job} <- schedule_next(%{job: job, report: report, datetime: datetime}) do
      :ok
    else
      {:cancel, reason} ->
        {:cancel, reason}

      {:error, reason} ->
        Logger.error("Failed to send report: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp do_perform(%{
         report: %Report{
           id: report_id,
           org_id: org_id,
           integration_info: %{
             integration_id: integration_id,
             channel_id: channel_id
           },
           data_source_info: %{
             data_source_id: data_source_id,
             sql_template: sql_template,
             timezone: timezone,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period,
             columns: value_columns
           }
         },
         datetime: datetime
       }) do
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
         parsed_data = QueryData.refine_data_based_on_columns(raw_data, value_columns),
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
    else
      {:error, {:resource_not_found, %{target: Report}}} ->
        {:cancel, :report_is_deleted}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp schedule_next(%{
         job: %Oban.Job{args: args, meta: meta},
         report: %Report{trigger_time: trigger_time},
         datetime: datetime
       }) do
    new_datetime = DateTimeHelper.get_next_with_time(datetime, trigger_time)
    new_scheduled_at = new_datetime

    {:ok, next_job} =
      %{args | "datetime" => new_datetime}
      |> new(meta: meta, scheduled_at: new_scheduled_at)
      |> then(&Oban.insert(CarrierWorker.Oban, &1))

    Logger.debug("next job is scheduled_at #{inspect(new_scheduled_at)}")

    {:ok, next_job}
  end
end
