defmodule CarrierWeb.MainComponents do
  use Phoenix.Component
  alias CarrierWeb.CoreComponents

  attr :rest, :global

  slot :inner_block

  def page_container(assigns) do
    ~H"""
    <div class="py-8 bg-base max-w-7xl px-6" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :icon, :any, required: true

  slot :inner_block

  def page_header(assigns) do
    ~H"""
    <header class="flex justify-between items-center">
      <h1 class="font-bold text-2xl">
        <span class="mr-3"><%= @icon %></span> <%= @title %>
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
    <div class={["mt-4", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["card", @class]}>
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

  attr :last?, :boolean, required: true

  def infinite_scroll_loader(assigns) do
    ~H"""
    <div id="infinite-scroll-marker" phx-hook="InfiniteScroll" class="w-full text-center">
      <CoreComponents.loading :if={!@last?} />
    </div>
    """
  end
end
