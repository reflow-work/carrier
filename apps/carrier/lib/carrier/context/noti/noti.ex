defmodule Carrier.Noti do
  alias Carrier.External.Slack

  def send_report_to_slack(channel, args, token) do
    blocks = args |> report_to_slack_block()

    Slack.post_message(channel, blocks, token)
  end

  defp report_to_slack_block( %{
         title: title,
         raw: %{yesterday: raw_yesterday, last_week: raw_last_week},
         weekly_sum: %{last_week: weekly_sum_last_week, week_over_week: weekly_sum_week_over_week},
         img_url: img_url
       }
  ) do
[
      %{
        "text" => %{"text" => ":chart: *#{title}*", "type" => "mrkdwn"},
        "type" => "section"
      },
      %{
        "fields" => [
          %{"text" => "*Yesterday*", "type" => "mrkdwn"},
          %{"text" => "*Last Week*", "type" => "mrkdwn"},
          %{"text" => "#{raw_yesterday}", "type" => "plain_text"},
          %{"text" => "#{raw_last_week}", "type" => "plain_text"}
        ],
        "text" => %{"text" => "*Raw*", "type" => "mrkdwn"},
        "type" => "section"
      },
      %{
        "fields" => [
          %{"text" => "*Last Week*", "type" => "mrkdwn"},
          %{"text" => "*Week over Week*", "type" => "mrkdwn"},
          %{"text" => "#{weekly_sum_last_week}", "type" => "plain_text"},
          %{"text" => "#{weekly_sum_week_over_week}%", "type" => "plain_text"}
        ],
        "text" => %{"text" => "*Weekly Sum*", "type" => "mrkdwn"},
        "type" => "section"
      },
      %{"alt_text" => "chart-#{title}", "image_url" => img_url, "type" => "image"}
    ]
  end
end
