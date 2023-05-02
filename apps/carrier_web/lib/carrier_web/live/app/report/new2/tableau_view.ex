defmodule CarrierWeb.App.ReportLive.New2.TableauView do
  use CarrierWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p><%= @view.name %></p>
      <%= inspect(@view) %>
    </div>
    """
  end
end
