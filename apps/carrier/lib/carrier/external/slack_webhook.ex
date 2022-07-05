defmodule Carrier.External.SlackWebhook do
  use Tesla

  def send_message(url, message) do
    Tesla.post(client(url), "", %{"text" => message})
  end

  defp client(url) do
    [
      {Tesla.Middleware.BaseUrl, url},
      Tesla.Middleware.JSON
    ]
    |> Tesla.client()
  end
end
