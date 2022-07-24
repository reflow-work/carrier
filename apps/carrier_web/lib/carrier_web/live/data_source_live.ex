defmodule CarrierWeb.DataSourceLive do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Json is a babo</h1>
    """
  end
end
