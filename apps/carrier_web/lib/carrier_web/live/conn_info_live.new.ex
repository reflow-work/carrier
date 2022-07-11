defmodule CarrierWeb.ConnInfoLive.New do
  use CarrierWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>ConnInfo New</h1>

    <.form>
    </.form>
    """
  end
end
