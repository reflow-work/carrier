defmodule CarrierWeb.App.ReportLive.New2.RDBQueryMaker do
  use CarrierWeb, :live_component
  use Carrier.Data

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      hi
    </div>
    """
  end
end
