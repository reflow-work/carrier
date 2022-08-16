defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  alias Carrier.Accounts
  alias Carrier.Accounts.User

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
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    auth |> IO.inspect()

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

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    fails |> IO.inspect()

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end
end
