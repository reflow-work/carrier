defmodule Carrier.External.Slack do
  use Tesla

  @host "https://slack.com/api"

  plug Tesla.Middleware.BaseUrl, @host
  plug Tesla.Middleware.BearerAuth, token: get_token()
  plug Tesla.Middleware.JSON

  def post_message(channel_id, message) when is_binary(message) do
    %URI{
      path: "/chat.postMessage",
      query: %{channel: channel_id, text: message} |> URI.encode_query()
    }
    |> URI.to_string()
    |> get()
  end

  def post_message(channel_id, args) when is_map(args) do
    %URI{path: "/chat.postMessage"}
    |> URI.to_string()
    |> post(%{channel: channel_id, blocks: template(args)})
  end

  def get_public_channels() do
    %URI{path: "/conversations.list"}
    |> URI.to_string()
    |> get()
  end

  def get_access_token() do
    %URI{path: "/oauth.v2.access"}
    |> URI.to_string()
    |> get()
  end

  defp template(%{
         title: title,
         yesterday: %{raw: draw, wow: dwow},
         last_week: %{raw: wraw, wow: wwow},
         img_urls: img_urls
       }) do

    img_blocks = Enum.map(img_urls, fn img_url -> 
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
      },
    ] ++ img_blocks
  end

  def sample_args() do
    %{
      title: "total_sales",
      yesterday: %{
        raw: "123,456",
        wow: "1.5"
      },
      last_week: %{
        raw: "901,552",
        wow: "-8.3"
      },
      img_url:
        "https://www.investopedia.com/thmb/MCCSOI-i2RokZiuwSSDNae1xt8I=/660x0/filters:no_upscale():max_bytes(150000):strip_icc():format(webp)/dotdash_INV_Final_Line_Chart_Jan_2021-01-d2dc4eb9a59c43468e48c03e15501ebe.jpg"
    }
  end

  defp get_token() do
    Application.get_env(:carrier, :slack)[:bot_token]
  end
end
