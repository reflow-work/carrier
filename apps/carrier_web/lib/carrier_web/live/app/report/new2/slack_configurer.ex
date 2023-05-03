defmodule CarrierWeb.App.ReportLive.New2.SlackConfigurer do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Hi
    </div>
    """
  end
end
