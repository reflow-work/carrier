defmodule CarrierWeb.AuthPlug do
  use CarrierWeb, :plug
  import Phoenix.Controller, only: [redirect: 2, current_path: 1]

  alias Carrier.Accounts
  alias Carrier.Tenant

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"user_id" => user_id, "org_id" => org_id} <- get_session(conn),
         Tenant.put_org_id(org_id),
         {:ok, user} <- Accounts.fetch_user(user_id) do
      conn
      |> assign(:user, user)
    else
      _ ->
        conn
        |> clear_session()
        |> put_session(:user_return_to, current_path(conn))
        |> redirect(to: ~p"/login")
        |> halt()
    end
  end
end
