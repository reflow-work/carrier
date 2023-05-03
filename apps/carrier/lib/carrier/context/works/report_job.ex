defmodule Carrier.Works.ReportJob do
  use Oban.Worker,
    queue: :report,
    priority: 2,
    max_attempts: 2

  use Carrier.{Reports, Secrets}
  require Logger
  alias Carrier.Data.QueryData
  alias Carrier.Data.Source.Tableau
  alias Carrier.TenantRepo
  alias Carrier.External.Slack
  alias Carrier.Core.{DateHelper, Traversable}

  @query_date_length 28 + 7 + 28 + 1

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"org_id" => org_id, "report_id" => report_id, "datetime" => datetime_str}
      }) do
    TenantRepo.put_org_id(org_id)

    {:ok, datetime, _} = datetime_str |> DateTime.from_iso8601()

    with {:ok, %ReportLog{} = report_log} <-
           Reports.record_tried_report_log(%{report_id: report_id}),
         {:ok, %Report{} = report} <- Reports.fetch_report(report_id),
         {:ok, slack_args} <- generate_slack_args(%{report: report, datetime: datetime}),
         {:ok, %ReportLog{} = _updated_report_log} <-
           Reports.update_report_log(report_log, %{payload: slack_args}),
         {:ok, _result} <- send_report(%{report: report, slack_args: slack_args}),
         {:ok, _next_job} <- Reports.create_job_from_report(report, datetime) do
      :ok
    else
      {:error, {:resource_not_found, %{target: Report}}} ->
        Reports.record_cancelled_report_log(%{report_id: report_id})

        {:cancel, :report_is_deleted}

      {:error, reason} ->
        Reports.record_failed_report_log(%{report_id: report_id, error_message: inspect(reason)})
        Logger.error("Failed to send report: #{inspect(reason)}")

        {:error, reason}
    end
  rescue
    e ->
      Reports.record_failed_report_log(%{report_id: report_id, error_message: inspect(e)})
      Logger.error("Failed to send report: #{Exception.format(:error, e, __STACKTRACE__)}")

      {:error, e}
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(3)

  defp generate_slack_args(%{
         report: %Report{
           id: report_id,
           org_id: org_id,
           timezone: timezone,
           data_source_info: %{
             data_source_id: data_source_id,
             source: source,
             sql_template: sql_template,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period,
             columns: value_columns
           }
         },
         datetime: datetime
       })
       when source in [:postgres, :mysql, :bigquery, :athena] do
    with {:ok, %{columns: columns, data: data}} <-
           QueryData.query(%{
             org_id: org_id,
             data_source_id: data_source_id,
             sql_template: sql_template,
             datetime: datetime,
             timezone: timezone,
             query_date_length: @query_date_length
           }),
         {:ok, analyzed_data} <-
           QueryData.analyze(data, %{
             columns: columns,
             period: period,
             window_size: window_size,
             comparing_period: comparing_period
           }),
         parsed_data =
           QueryData.refine_data_based_on_columns(
             %{columns: columns, data: analyzed_data},
             value_columns,
             window_size
           ),
         {:ok, %{image_urls: image_urls}} <-
           ImageGenerator.gen_chart_images(%{
             org_id: org_id,
             report_id: report_id,
             data: parsed_data
           }),
         slack_args = Slack.build_post_message_args(parsed_data, image_urls) do
      {:ok, slack_args}
    end
  end

  defp generate_slack_args(%{
         report: %Report{
           id: report_id,
           org_id: org_id,
           data_source_info: %{
             data_source_id: data_source_id,
             source: :tableau,
             view_id: view_id,
             view_full_name: view_full_name
           }
         }
       }) do
    with {:ok, %DataSource{} = data_source} <-
           Secrets.fetch_data_source(data_source_id),
         {:ok, tableau_image_binary} =
           Tableau.get_view_image_binary(
             view_id,
             ConnInfo.to_credentials(data_source.conn_info)
           ),
         {:ok, url} <-
           ImageGenerator.upload_chart_image(%{
             org_id: org_id,
             report_id: report_id,
             binary: tableau_image_binary
           }),
         slack_args = [%{title: view_full_name, img_url: url}] do
      {:ok, slack_args}
    end
  end

  defp send_report(%{
         report: %Report{
           id: report_id,
           timezone: timezone,
           integration_info: %{
             integration_id: integration_id,
             channel_id: channel_id
           }
         },
         slack_args: slack_args
       }) do
    TenantRepo.wrap_transaction(fn ->
      with {:ok, %DataTarget{} = data_target} <- Secrets.fetch_integration(integration_id),
           {:ok, send_result} <-
             slack_args
             |> Enum.map(fn %{img_url: image_url, title: image_title} ->
               blocks = [
                 Slack.Block.build_text_block(report_title(timezone, image_title)),
                 Slack.Block.build_image_block(image_url, image_title, image_title)
               ]

               Slack.post_message(
                 channel_id,
                 blocks,
                 data_target.conn_info.info["bot_token"]
               )
             end)
             |> Traversable.traverse(),
           {:ok, _report_log} <- Reports.record_succeeded_report_log(%{report_id: report_id}) do
        {:ok, send_result}
      end
    end)
  end

  defp report_title(timezone, title) do
    # TODO: 이후에 구조를 바꿔서 리포트에 찍히는 날짜와 동일한 날짜로 바꿔야함
    "*📊 #{DateTime.now!(timezone) |> Timex.shift(days: -1) |> DateHelper.safe_format_date()} - #{title}*"
  end
end
