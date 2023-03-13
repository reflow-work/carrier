defmodule Carrier.External.Slack.Block do
  def build_text_block(text, type \\ "mrkdwn") do
    %{
      "type" => "section",
      "text" => %{
        "type" => type,
        "text" => text
      }
    }
  end

  def build_image_block(url, title, alt_text) do
    image_url = url |> URI.encode()

    %{
      "type" => "image",
      "title" => %{
        "type" => "plain_text",
        "text" => title,
        "emoji" => false
      },
      "image_url" => image_url,
      "alt_text" => alt_text
    }
  end
end
