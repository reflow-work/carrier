defmodule CarrierWeb.MainComponents do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :icon, :any, required: true

  slot :inner_block

  def page_header(assigns) do
    ~H"""
    <header class="page-header items-center">
      <h1 class="page-title">
        <span class="page-title-icon"><%= @icon %></span> <%= @title %>
      </h1>

      <div>
        <%= render_slot(@inner_block) %>
      </div>
    </header>
    """
  end
end
