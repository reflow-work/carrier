defmodule CarrierWeb.App.DataSourceLive.New do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={CarrierWeb.Components.DataSourceNew} id="data_source_new" org={@org} />
    """
  end
end
