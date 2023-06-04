defmodule CarrierWeb.App.DataTargetController do
  use CarrierWeb, :controller
  use Carrier.Integrations
  alias Carrier.External.SlackAPI

  def slack_callback(conn, %{"code" => code}) do
    org_id = conn |> get_session(:org_id)

    with {:ok, %{access_token: bot_token, team: %{id: team_id, name: team_name}}} <-
           SlackAPI.OAuth.get_access_token(%{code: code}),
         {:ok, %DataTarget{}} <-
           Integrations.create_data_target(%{
             org_id: org_id,
             service_name: :slack,
             conn_info: %{team_name: team_name, team_id: team_id, bot_token: bot_token}
           }) do
      conn
      |> redirect(to: ~p"/app/reports")
    else
      error ->
        conn
        |> put_flash(:error, inspect(error))
        |> redirect(to: "/")
    end
  end
end
