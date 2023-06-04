defmodule Carrier.External.SlackAPI.OAuth do
  use Tesla
  require Logger

  @host "https://slack.com/api"

  plug Tesla.Middleware.BaseUrl, @host
  plug Tesla.Middleware.FormUrlencoded

  @path "https://slack.com/oauth/v2/authorize"
  def generate_url() do
    query = %{
      scope: ["channels:read", "chat:write", "chat:write.public"] |> Enum.join(","),
      redirect_uri: nil,
      client_id: client_id()
    }

    @path
    |> URI.parse()
    |> Map.put(:query, query |> URI.encode_query())
    |> URI.to_string()
  end

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
    |> case do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        %{"access_token" => access_token, "team" => %{"id" => team_id, "name" => team_name}} =
          body |> Jason.decode!()

        {:ok, %{access_token: access_token, team: %{id: team_id, name: team_name}}}

      error ->
        Logger.error(inspect(error))

        {:error, :slack_api_oauth2_failed}
    end
  end

  defp client_id() do
    Application.get_env(:carrier, :slack)[:client_id]
  end

  defp client_secret() do
    Application.get_env(:carrier, :slack)[:client_secret]
  end
end
