defmodule Carrier.Noti do
  alias Carrier.External.Slack

  def send_report_to_slack(channel, args, token) do
    blocks = args |> report_to_slack_block()

    Slack.post_message(channel, blocks, token)
  end

  defp report_to_slack_block(%{
         title: title,
         img_url: img_url
       }) do
    img_url = img_url |> URI.encode()

    [
      %{"alt_text" => "chart-#{title}", "image_url" => img_url, "type" => "image"}
    ]
  end
end
