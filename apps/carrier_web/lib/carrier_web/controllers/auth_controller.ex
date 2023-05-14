defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  alias Carrier.{Accounts, Integrations}
  alias Carrier.Accounts.{User}
  alias Carrier.Obfuscatable
  alias Carrier.Integrations.DataTarget

  plug Ueberauth

  def login(conn, _params) do
    case get_session(conn, "user_id") do
      nil ->
        conn
        |> render(:login)

      _ ->
        conn
        |> redirect(to: ~p"/app/reports")
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end

  def invite(conn, %{"token" => token}) do
    org_id = token |> Obfuscatable.deobfuscate!()

    case Accounts.Super.get_org(org_id) do
      {:ok, org} ->
        conn
        |> put_session(:org_id, org_id)
        |> render(:invite, org: org)

      _ ->
        conn
        |> render(:invite, org: nil)
    end
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{provider: provider} = auth}} = conn,
        _params
      ) do
    _conn =
      case provider do
        :google -> auth(conn, auth)
        :slack -> add_conn_info_to_org(conn, auth)
      end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "로그인에 실패하였습니다. 다시 시도해주세요.")
    |> redirect(to: "/")
  end

  defp auth(conn, auth) do
    %Ueberauth.Auth{
      provider: :google,
      info: %Ueberauth.Auth.Info{
        email: email
      }
    } = auth

    org_id = conn |> get_session(:org_id)

    case Accounts.Super.auth(email, org_id) do
      {:ok, {_, %User{id: user_id, org_id: org_id}}} ->
        conn
        |> put_session(:user_id, user_id)
        |> put_session(:org_id, org_id)
        |> redirect(to: get_session(conn, :user_return_to) || ~p"/app/reports?redirected=true")

      _ ->
        conn
        |> put_flash(:error, "로그인에 실패하였습니다. 다시 시도해주세요.")
        |> redirect(to: "/")
    end
  end

  defp add_conn_info_to_org(conn, auth) do
    %Ueberauth.Auth{
      provider: :slack,
      credentials: %Ueberauth.Auth.Credentials{
        token: bot_token,
        other: %{
          team: team_name,
          team_id: team_id
        }
      }
    } = auth

    org_id = conn |> get_session(:org_id)

    case Integrations.create_data_target(%{
           org_id: org_id,
           service_name: :slack,
           conn_info: %{team_name: team_name, team_id: team_id, bot_token: bot_token}
         }) do
      {:ok, %DataTarget{}} ->
        conn
        |> redirect(to: ~p"/app/reports")

      error ->
        conn
        |> put_flash(:error, inspect(error))
        |> redirect(to: "/")
    end
  end
end
