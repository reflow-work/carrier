defmodule CarrierWeb.IntegrationLive.New do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Slack

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
