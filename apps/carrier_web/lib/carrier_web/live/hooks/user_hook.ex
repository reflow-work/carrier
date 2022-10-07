defmodule CarrierWeb.UserHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts
  alias Carrier.TenantRepo

  def on_mount(:default, _params, %{"org_id" => org_id, "user_id" => user_id}, socket) do
    TenantRepo.put_org_id(org_id)

    case Accounts.fetch_user(user_id) do
      {:ok, %User{} = user} ->
        socket =
          socket
          |> assign(:org_id, org_id)
          |> assign(:user, user)

        {:cont, socket}

      _ ->
        socket =
          socket
          |> redirect(to: Routes.auth_path(socket, :login))

        {:halt, socket}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> redirect(to: Routes.auth_path(socket, :login))

    {:halt, socket}
  end
end
