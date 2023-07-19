defmodule CarrierWeb.App.DataTargetController do
  use CarrierWeb, :controller
  use Carrier.Integrations
  alias CarrierWeb.Helpers.SlackHelper
  alias Carrier.Tenant
  alias Carrier.Obfuscatable
  alias Carrier.External.SlackAPI

  def slack_callback(conn, %{"code" => code} = params) do
    org_id = conn |> get_session(:org_id)
    Tenant.put_org_id(org_id)
    obfuscated_data_target_id = params["data_target_id"]

    redirect_uri = SlackHelper.get_redirect_uri(obfuscated_data_target_id, params["popup"])

    with {:ok, credentials} <-
           SlackAPI.OAuth.get_access_token(%{code: code, redirect_uri: redirect_uri}),
         {:ok, %DataTarget{} = data_target} <-
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

                Integrations.update_conn_info_of_data_target(data_target_id, %{info: credentials})
            end) do
      case params["popup"] do
        "true" ->
          conn
          |> render(:popup, data_target_id: Obfuscatable.obfuscate(data_target))

        _ ->
          conn
          |> redirect(to: ~p"/app/reports")
      end
    else
      error ->
        conn
        |> put_flash(:error, inspect(error))
        |> redirect(to: "/")
    end
  end
end
