defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  use Carrier.Accounts
  require Logger
  alias Carrier.Obfuscatable
  alias Carrier.External.Google
  alias Carrier.Core.Nillable

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

  def invite(conn, %{"invite_token" => invite_token}) do
    org_id = invite_token |> Obfuscatable.deobfuscate!(Org)

    case Accounts.Super.get_org(org_id) do
      {:ok, org} ->
        conn
        |> render(:invite, org: org, invite_token: invite_token)

      _ ->
        conn
        |> render(:invite, org: nil, invite_token: nil)
    end
  end

  def google_callback(
        conn,
        %{"g_csrf_token" => g_csrf_token, "credential" => credential} = params
      ) do
    invited_org_id = params["invite_token"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Org))

    with :ok <- check_google_csrf(conn, g_csrf_token),
         {:ok, %{email: email}} <- Google.OAuth.verify_credential(credential),
         {:ok, {_, %User{id: user_id, org_id: org_id}}} <-
           Accounts.Super.auth(email, invited_org_id) do
      conn
      |> put_session(:user_id, user_id)
      |> put_session(:org_id, org_id)
      |> redirect(to: get_session(conn, :user_return_to) || ~p"/app/reports?redirected=true")
    else
      error ->
        Logger.error("Google OAuth error: #{inspect(error)}")

        conn
        |> put_flash(:error, "로그인에 실패하였습니다. 다시 시도해주세요.")
        |> redirect(to: "/login")
    end
  end

  defp check_google_csrf(conn, g_csrf_token) do
    case conn.req_cookies["g_csrf_token"] == g_csrf_token do
      true -> :ok
      false -> {:error, "Invalid CSRF token"}
    end
  end
end
