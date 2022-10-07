defmodule Carrier.Works.ReportJob do
  use Oban.Worker, queue: :default, max_attempts: 1
  use Carrier.Reports
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
  def perform(%Oban.Job{
        args: %{"org_id" => org_id, "report_id" => report_id, "datetime" => datetime_str}
      }) do
    TenantRepo.put_org_id(org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %ReportLog{} = report_log} <-
           Reports.record_tried_report_log(%{report_id: report_id}),
         {:ok, %Report{} = report} <- Reports.fetch_report(report_id),
         {:ok, %ReportLog{} = _updated_report_log} <-
           Reports.update_report_log(report_log, %{
             integration_info: report.integration_info |> Map.from_struct(),
             data_source_info: report.data_source_info |> Map.from_struct()
           }),
         {:ok, slack_args} <- generate_slack_args(%{report: report, datetime: datetime}),
         {:ok, _next_job} <-
           send_report(%{report: report, slack_args: slack_args, datetime: datetime}) do
      :ok
    else
      {:error, {:resource_not_found, %{target: Report}}} ->
        {:cancel, :report_is_deleted}

      {:error, reason} ->
        Reports.record_failed_report_log(%{report_id: report_id, error_message: inspect(reason)})
        Logger.error("Failed to send report: #{inspect(reason)}")

        {:error, reason}
    end
  rescue
    e ->
      Reports.record_failed_report_log(%{report_id: report_id, error_message: inspect(e)})
      Logger.error("Failed to send report: #{inspect(e)}")

      {:error, e}
  end

  defp generate_slack_args(%{
         report: %Report{
           id: report_id,
           org_id: org_id,
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
    with {:ok, raw_data} <-
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
         slack_args = Slack.build_post_message_args(parsed_data, img_urls) do
      {:ok, slack_args}
    end
  end

  defp send_report(%{
         report:
           %Report{
             id: report_id,
             integration_info: %{
               integration_id: integration_id,
               channel_id: channel_id
             }
           } = report,
         slack_args: slack_args,
         datetime: datetime
       }) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %Integration{} = integration} <- Secrets.fetch_integration(integration_id),
           {:ok, _} <-
             slack_args
             |> Enum.map(
               &Noti.send_report_to_slack(channel_id, &1, integration.conn_info.info["bot_token"])
             )
             |> Traversable.traverse(),
           {:ok, _report_log} <- Reports.record_succeeded_report_log(%{report_id: report_id}),
           {:ok, next_job} <- Reports.create_job_from_report(report, datetime) do
        {:ok, next_job}
      end
    end)
  end
end
