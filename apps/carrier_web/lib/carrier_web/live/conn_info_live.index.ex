defmodule CarrierWeb.ConnInfoLive.Index do
  use CarrierWeb, :live_view
  alias Phoenix.LiveView.JS
  alias Carrier.Secrets
  alias Carrier.TenantRepo

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    TenantRepo.put_org_id(org_id)

    socket =
      socket
      |> assign_new(:org_id, fn -> org_id end)
      |> assign_new(:conn_infos, fn -> load_conn_infos(org_id) end)
      |> assign_new(:count, fn -> 1 end)

    {:ok, socket}
  end

  @impl true
  def handle_event("plus_count", _params, socket) do
    socket =
      socket
      |> update(:count, fn count -> count + 1 end)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>ConnInfo Index</h1>
    <p>org_id: <%= @org_id %></p>

    <div>
      <%= for conn_info <- @conn_infos do %>
        <%= render_conn_info(%{conn_info: conn_info}) %>
      <% end %>
    </div>

    <p id="count">count: <%= @count %></p>

    <button id="plus_count" phx-click={plus_count()} phx-hook="Count">+</button>

    <div>
      <%= live_redirect "new", to: Routes.conn_info_new_path(@socket, :new) %>
    </div>
    """
  end

  defp render_conn_info(assigns) do
    ~H"""
    <div>
      <p>name: <%= @conn_info.name %></p>
      <p>type: <%= @conn_info.type %></p>
      <p>hostname: <%= @conn_info.info["hostname"] %></p>
    </div>
    """
  end

  defp plus_count() do
    JS.push("plus_count")
    |> JS.toggle(to: "#count", in: "fade-in-scale", out: "fade-out-scale")
  end

  defp load_conn_infos(_socket) do
    Secrets.list_conn_infos()
  end
end
