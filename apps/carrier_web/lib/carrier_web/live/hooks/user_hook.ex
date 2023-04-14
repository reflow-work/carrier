defmodule CarrierWeb.UserHook do
  use CarrierWeb, :live_hook
  use Carrier.Accounts
  require Logger
  alias Carrier.TenantRepo
  alias Carrier.Core.Nillable

  def on_mount(:default, _params, %{"org_id" => org_id, "user_id" => user_id}, socket) do
    Logger.metadata(org_id: org_id, user_id: user_id)

    TenantRepo.put_org_id(org_id)

    socket = socket |> assign_new_user(user_id)

    case socket.assigns.user do
      nil ->
        socket = socket |> redirect(to: ~p"/logout")

        {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    socket = socket |> redirect(to: ~p"/logout")

    {:halt, socket}
  end

  defp assign_new_user(socket, user_id) do
    socket
    |> assign_new(:user, fn -> load_user(user_id) end)
    |> assign_new(:org, fn %{user: maybe_user} ->
      maybe_user |> Nillable.map(fn %User{org: org} -> org end)
    end)
  end

  defp load_user(user_id) do
    case Accounts.fetch_user(user_id) do
      {:ok, %User{} = user} -> user
      _ -> nil
    end
  end
end
