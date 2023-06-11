defmodule Carrier.External.SlackAPI.Block do
  def build_text_block(text, type \\ "mrkdwn", should_escape \\ true) do
    %{
      "type" => "section",
      "text" => %{
        "type" => type,
        "text" => escape_text(text, should_escape)
      }
    }
  end

  def build_link_block(text, url, should_escape \\ true) do
    %{
      "type" => "section",
      "text" => %{
        "type" => "mrkdwn",
        "text" => "<#{url}|#{escape_text(text, should_escape)}>"
      }
    }
  end

  def build_image_block(url, title, alt_text, should_escape \\ true) do
    encoded_url = url |> URI.encode()

    %{
      "type" => "image",
      "title" => %{
        "type" => "plain_text",
        "text" => escape_text(title, should_escape),
        "emoji" => false
      },
      "image_url" => encoded_url,
      "alt_text" => escape_text(alt_text, should_escape)
    }
  end

  def build_button_block(text, url, should_escape \\ true) do
    encoded_url = url |> URI.encode()

    %{
      "type" => "actions",
      "elements" => [
        %{
          "type" => "button",
          "text" => %{
            "type" => "plain_text",
            "text" => escape_text(text, should_escape),
            "emoji" => false
          },
          "url" => encoded_url
        }
      ]
    }
  end

  def build_divider_block() do
    %{
      "type" => "divider"
    }
  end

  defp escape_text(text, true) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_text(text, false) do
    text
  end
end
