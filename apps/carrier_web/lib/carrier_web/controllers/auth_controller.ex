defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  use Carrier.Accounts
  alias Carrier.Obfuscatable

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
    org_id = token |> Obfuscatable.deobfuscate!(Org)

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

  def google_callback(conn, %{"credential" => credential}) do
    # TODO: implement it

    conn
    |> redirect(to: ~p"/login")
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
end
