defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""

    """
  end
end
