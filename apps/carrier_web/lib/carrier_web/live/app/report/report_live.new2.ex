defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view

  on_mount(CarrierWeb.IntegrationHook)
  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{live_action: :new}} = socket) do
    socket =
      socket
      |> assign(:title, "레포트 생성하기")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <header class="page-header">
        <h1 class="page-title">
          <span class="page-title-icon">📊</span> <%= @title %>
        </h1>
      </header>
    </section>
    """
  end
end
