defmodule CarrierWeb.UserHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts
  alias Carrier.TenantRepo

  def on_mount(:default, _params, %{"org_id" => org_id, "user_id" => user_id}, socket) do
    TenantRepo.put_org_id(org_id)

    socket =
      socket
      |> assign_new_user(%{org_id: org_id, user_id: user_id})

    case socket.assigns.user do
      nil ->
        socket =
          socket
          |> redirect(to: Routes.auth_path(socket, :logout))

        {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> redirect(to: Routes.auth_path(socket, :logout))

    {:halt, socket}
  end

  defp assign_new_user(socket, %{org_id: org_id, user_id: user_id}) do
    socket
    |> assign_new(:org_id, fn -> org_id end)
    |> assign_new(:user, fn -> load_user(user_id) end)
  end

  defp load_user(user_id) do
    case Accounts.fetch_user(user_id) do
      {:ok, %User{} = user} -> user
      _ -> nil
    end
  end
end
