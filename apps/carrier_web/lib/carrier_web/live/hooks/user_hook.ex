defmodule CarrierWeb.UserHook do
  use CarrierWeb, :live_hook
  alias Carrier.TenantRepo

  def on_mount(:default, _params, _session, socket) do
    org_id = 1

    socket = socket |> assign(org_id: org_id)
    TenantRepo.put_org_id(org_id)

    {:cont, socket}
  end
end
