defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  alias Carrier.Accounts
  alias Carrier.Accounts.User

  plug Ueberauth

  def login(conn, _params) do
    conn
    |> render("login.html")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
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

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end
end
