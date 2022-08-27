defmodule CarrierWeb.IntegrationLive.New do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Integration New
    """
  end
end
