defmodule Carrier.External.Slack do
  @host "https://slack.com/api"

  def post_message(channel_id, message, token) when is_binary(message) do
    query = [channel: channel_id, text: message]

    Tesla.get(client(token), "/chat.postMessage", query: query)
    |> handle_response()
    |> case do
      {:ok, body} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def post_message(channel_id, blocks, token) when is_list(blocks) do
    body = %{channel: channel_id, blocks: blocks}

    Tesla.post(client(token), "/chat.postMessage", body: body)
    |> handle_response()
    |> case do
      {:ok, body} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # def get_public_channels() do
  #   %URI{path: "/conversations.list"}
  #   |> URI.to_string()
  #   |> get()
  # end

  # def get_access_token() do
  #   %URI{path: "/oauth.v2.access"}
  #   |> URI.to_string()
  #   |> get()
  # end

  defp handle_response(response) do
    case response do
      {:ok, %Tesla.Env{status: 200, body: %{"ok" => true} = body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: %{"ok" => false, "error" => reason}}} ->
        {:error, reason}

      {:ok, %Tesla.Env{status: _, body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client(token) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, @host},
      {Tesla.Middleware.BearerAuth, token: token},
      Tesla.Middleware.JSON
    ])
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
end
