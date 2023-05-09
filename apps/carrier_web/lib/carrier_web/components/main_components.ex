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

  attr :class, :string, default: "space-y-8"

  slot :inner_block, required: true

  def card_container(assigns) do
    ~H"""
    <div class={["mt-6", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["card !rounded-md", @class]}>
      <div class="card-body">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :title, :string, required: true

  def card_title(assigns) do
    ~H"""
    <h2 class={["card-title mb-2 text-base text-black", @class]}><%= @title %></h2>
    """
  end
end
