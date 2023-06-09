defmodule Carrier.External.SlackAPI.Block do
  def build_text_block(text, type \\ "mrkdwn") do
    %{
      "type" => "section",
      "text" => %{
        "type" => type,
        "text" => escape_text(text)
      }
    }
  end

  def build_link_block(text, url) do
    %{
      "type" => "section",
      "text" => %{
        "type" => "mrkdwn",
        "text" => "<#{url}|#{escape_text(text)}>"
      }
    }
  end

  def build_image_block(url, title, alt_text) do
    encoded_url = url |> URI.encode()

    %{
      "type" => "image",
      "title" => %{
        "type" => "plain_text",
        "text" => escape_text(title),
        "emoji" => false
      },
      "image_url" => encoded_url,
      "alt_text" => alt_text
    }
  end

  def build_button_block(text, url) do
    encoded_url = url |> URI.encode()

    %{
      "type" => "actions",
      "elements" => [
        %{
          "type" => "button",
          "text" => %{
            "type" => "plain_text",
            "text" => escape_text(text),
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

  defp escape_text(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
