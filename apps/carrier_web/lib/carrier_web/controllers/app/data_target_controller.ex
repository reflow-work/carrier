defmodule CarrierWeb.App.DataTargetController do
  use CarrierWeb, :controller
  use Carrier.Integrations
  alias CarrierWeb.Helpers.SlackHelper
  alias Carrier.TenantRepo
  alias Carrier.External.SlackAPI

  def slack_callback(conn, %{"code" => code} = params) do
    org_id = conn |> get_session(:org_id)
    TenantRepo.put_org_id(org_id)
    obfuscated_data_target_id = params["data_target_id"]

    redirect_uri = SlackHelper.get_redirect_uri(obfuscated_data_target_id)

    with {:ok, credentials} <-
           SlackAPI.OAuth.get_access_token(%{code: code, redirect_uri: redirect_uri}),
         {:ok, %DataTarget{}} <-
           (case obfuscated_data_target_id do
              nil ->
                Integrations.create_data_target(%{
                  org_id: org_id,
                  service_name: :slack,
                  conn_info: credentials
                })

              obfuscated_data_target_id ->
                data_target_id =
                  obfuscated_data_target_id |> Carrier.Obfuscatable.deobfuscate!(DataTarget)

                # TODO: implement it
                {:ok, %DataTarget{id: data_target_id}}
            end) do
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
