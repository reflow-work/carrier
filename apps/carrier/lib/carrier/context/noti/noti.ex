defmodule Carrier.Noti do
  alias Carrier.External.Slack

  def send_report_to_slack(channel, args, token) do
    blocks = args |> report_to_slack_block()

    Slack.post_message(channel, blocks, token)
  end

  defp report_to_slack_block(%{
         title: title,
         yesterday: %{raw: draw, wow: dwow},
         last_week: %{raw: wraw, wow: wwow},
         img_urls: img_urls
       }) do
    img_blocks =
      Enum.map(img_urls, fn img_url ->
        %{"alt_text" => "chart-#{title}", "image_url" => img_url, "type" => "image"}
      end)

    [
      %{
        "text" => %{"text" => ":chart: *#{title}*", "type" => "mrkdwn"},
        "type" => "section"
      },
      %{
        "fields" => [
          %{"text" => "*Raw*", "type" => "mrkdwn"},
          %{"text" => "*Week over Week*", "type" => "mrkdwn"},
          %{"text" => "#{draw}", "type" => "plain_text"},
          %{"text" => "#{dwow}%", "type" => "plain_text"}
        ],
        "text" => %{"text" => "*Yesterday*", "type" => "mrkdwn"},
        "type" => "section"
      },
      %{
        "fields" => [
          %{"text" => "*Raw*", "type" => "mrkdwn"},
          %{"text" => "*Week over Week*", "type" => "mrkdwn"},
          %{"text" => "#{wraw}", "type" => "plain_text"},
          %{"text" => "#{wwow}%", "type" => "plain_text"}
        ],
        "text" => %{"text" => "*Last Week*", "type" => "mrkdwn"},
        "type" => "section"
      }
    ] ++ img_blocks
  end
end
