defmodule CarrierWeb.DataSourceLive.Index do
  use CarrierWeb, :live_view

  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
