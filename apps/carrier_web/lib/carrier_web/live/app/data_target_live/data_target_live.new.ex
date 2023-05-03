defmodule CarrierWeb.App.DataTargetLive.New do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Slack

  on_mount(CarrierWeb.NoDataTargetHook)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
