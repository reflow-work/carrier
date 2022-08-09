defmodule CarrierWeb.AuthController do
  use CarrierWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: _auth}} = conn, _params) do
    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end
end
