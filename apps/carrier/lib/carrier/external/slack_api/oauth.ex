defmodule Carrier.External.SlackAPI.OAuth do
  use Tesla
  require Logger

  @host "https://slack.com/api"

  plug Tesla.Middleware.BaseUrl, @host
  plug Tesla.Middleware.FormUrlencoded

  @path "https://slack.com/oauth/v2/authorize"
  def generate_url() do
    query = %{
      scope:
        [
          # common
          "chat:write",
          # public channel
          "channels:read",
          "chat:write.public",
          # private channel
          "groups:read",
          # direct message
          "users:read",
          "im:read"
        ]
        |> Enum.join(","),
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
    |> handle_response()
    |> case do
      {:ok,
       %{
         "access_token" => bot_access_token,
         "scope" => bot_scope,
         "team" => %{"id" => team_id, "name" => team_name}
       }} ->
        {:ok,
         %{
           bot_scope: bot_scope,
           bot_token: bot_access_token,
           team_id: team_id,
           team_name: team_name
         }}

      {:error, reason} ->
        Logger.error(reason)

        {:error, reason}
    end
  end

  def handle_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    case body |> Jason.decode!() do
      %{"ok" => true} = json_body ->
        {:ok, json_body}

      %{"ok" => false, "error" => error} ->
        {:error, error}
    end
  end

  def handle_response({:error, reason}) do
    {:error, reason}
  end

  defp client_id() do
    Application.get_env(:carrier, :slack)[:client_id]
  end

  defp client_secret() do
    Application.get_env(:carrier, :slack)[:client_secret]
  end
end
