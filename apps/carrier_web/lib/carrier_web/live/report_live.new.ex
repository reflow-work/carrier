defmodule CarrierWeb.ReportLive.New do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    ReportNew
    """
  end
end
