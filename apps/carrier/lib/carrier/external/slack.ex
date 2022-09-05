defmodule Carrier.External.Slack do
  @host "https://slack.com/api"

  def post_message(channel_id, message, token) when is_binary(message) do
    query = [channel: channel_id, text: message]

    Tesla.get(client(token), "/chat.postMessage", query: query)
    |> handle_response()
    |> case do
      {:ok, _body} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def post_message(channel_id, blocks, token) when is_list(blocks) do
    body = %{channel: channel_id, blocks: blocks}

    Tesla.post(client(token), "/chat.postMessage", body)
    |> handle_response()
    |> case do
      {:ok, _body} -> :ok
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

  # data :: %{ dynamic_column_name: %{ data: list(), meta: map() }, ... }
  def build_post_message_args(data, img_urls) do
    data
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      %{
        title: v.meta.label,
        raw: %{
          yesterday: v.meta.current_period_last_tick_raw,
          last_week: v.meta.previous_period_last_tick_raw
        },
        weekly_sum: %{
          last_week: v.meta.current_period_sum,
          week_over_week: v.meta.diff_between_periods_in_percentage
        },
        img_url: Map.get(img_urls, k)
      }
    end)
  end

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
      raw: %{
        yesterday: "123,456",
        last_week: "1.5"
      },
      weekly_sum: %{
        last_week: "901,552",
        week_over_week: "-8.3"
      },
      img_url:
        "https://www.investopedia.com/thmb/MCCSOI-i2RokZiuwSSDNae1xt8I=/660x0/filters:no_upscale():max_bytes(150000):strip_icc():format(webp)/dotdash_INV_Final_Line_Chart_Jan_2021-01-d2dc4eb9a59c43468e48c03e15501ebe.jpg"
    }
  end
end
