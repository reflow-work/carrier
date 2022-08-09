defmodule CarrierWeb.UserHook do
  use CarrierWeb, :live_hook
  alias Carrier.TenantRepo

  def on_mount(:default, _params, %{"org_id" => org_id, "user_id" => user_id}, socket) do
    socket =
      socket
      |> assign(org_id: org_id)
      |> assign(user_id: user_id)

    TenantRepo.put_org_id(org_id)

    {:cont, socket}
  end
end
