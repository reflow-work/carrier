defmodule CarrierWeb.ReportLive.Index do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Report Live
    """
  end
end
