defmodule Carrier.Noti do
  alias Carrier.External.Slack
  alias Carrier.External.SlackBlock

  def send_report_to_slack(channel, args, token) do
    blocks = args |> report_to_slack_block()

    Slack.post_message(channel, blocks, token)
  end

  defp report_to_slack_block(%{
         title: title,
         img_url: img_url
       }) do
    [
      SlackBlock.build_image(img_url, title, title)
    ]
  end
end
