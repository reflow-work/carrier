defmodule Carrier.External.Slack do
  use Tesla

  @host "https://slack.com/api"

  plug Tesla.Middleware.BaseUrl, @host
  plug Tesla.Middleware.BearerAuth, token: get_token()
  plug Tesla.Middleware.JSON

  def post_message(channel_id, message) do
    %URI{
      path: "/chat.postMessage",
      query: %{channel: channel_id, text: message} |> URI.encode_query()
    }
    |> URI.to_string()
    |> get()
  end

  defp get_token() do
    Application.get_env(:carrier, :slack)[:bot_token]
  end
end
