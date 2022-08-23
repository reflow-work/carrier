defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  alias Carrier.{Accounts, Secrets}
  alias Carrier.Accounts.User
  alias Carrier.Secrets.Integration

  plug Ueberauth

  def login(conn, _params) do
    case get_session(conn, "user_id") do
      nil ->
        conn
        |> render("login.html")

      _ ->
        conn
        |> redirect(to: Routes.data_source_path(conn, :new))
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: Routes.auth_path(conn, :login))
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{provider: provider} = auth}} = conn,
        _params
      ) do
    auth |> IO.inspect()

    _conn =
      case provider do
        :google -> auth(conn, auth)
        :slack -> add_conn_info_to_org(conn, auth)
      end
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    fails |> IO.inspect()

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  defp auth(conn, auth) do
    %Ueberauth.Auth{
      info: %Ueberauth.Auth.Info{
        email: email
      }
    } = auth

    case Accounts.auth(email) do
      {:ok, {_, %User{id: user_id, org_id: org_id}}} ->
        conn
        |> put_session(:user_id, user_id)
        |> put_session(:org_id, org_id)
        |> put_flash(:info, "Successfully authenticated.")
        |> redirect(to: Routes.data_source_path(conn, :new))

      _ ->
        conn
        |> put_flash(:error, "Failed to authenticate.")
        |> redirect(to: "/")
    end
  end

  defp add_conn_info_to_org(conn, auth) do
    %Ueberauth.Auth{
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          auth: %{
            "team" => team_name,
            "team_id" => team_id
          }
        }
      }
    } = auth

    org_id = conn |> get_session(:org_id)

    case Secrets.create_integration(%{
           org_id: org_id,
           service_name: :slack,
           conn_info: %{team_name: team_name, team_id: team_id}
         }) do
      {:ok, %Integration{}} ->
        conn
        |> redirect(to: "/")

      error ->
        conn
        |> put_flash(:error, inspect(error))
        |> redirect(to: "/")
    end
  end
end
