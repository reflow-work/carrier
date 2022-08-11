defmodule Carrier.External.Slack.Oauth do
  use Tesla

  @host "https://slack.com/api"

  plug Tesla.Middleware.BaseUrl, @host
  plug Tesla.Middleware.FormUrlencoded

  def get_access_token(%{code: code}) do
    body = %{
      client_id: client_id(),
      client_secret: client_secret(),
      code: code,
      grant_type: "authorization_code"
    }

    %URI{path: "/oauth.v2.access"}
    |> URI.to_string()
    |> post(body)
  end

  defp client_id() do
    Application.get_env(:carrier, :slack)[:client_id]
  end

  defp client_secret() do
    Application.get_env(:carrier, :slack)[:client_secret]
  end
end
