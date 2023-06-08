defmodule CarrierWeb.App.DataTargetController do
  use CarrierWeb, :controller
  use Carrier.Integrations
  alias Carrier.External.SlackAPI

  def slack_callback(conn, %{"code" => code}) do
    org_id = conn |> get_session(:org_id)

    with {:ok, credentials} <- SlackAPI.OAuth.get_access_token(%{code: code}),
         {:ok, %DataTarget{}} <-
           Integrations.create_data_target(%{
             org_id: org_id,
             service_name: :slack,
             conn_info: credentials
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
