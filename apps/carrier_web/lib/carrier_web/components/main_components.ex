defmodule CarrierWeb.MainComponents do
  use Phoenix.Component

  attr(:rest, :global)

  slot(:inner_block)

  def page_container(assigns) do
    ~H"""
    <div class="py-8 bg-base max-w-7xl px-6" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:icon, :any, required: true)

  slot(:inner_block)

  def page_header(assigns) do
    ~H"""
    <header class="flex justify-between items-center">
      <h1 class="font-bold text-2xl">
        <span class="mr-3"><%= @icon %></span> <%= @title %>
      </h1>

      <div class="flex justify-between items-center">
        <%= render_slot(@inner_block) %>
      </div>
    </header>
    """
  end

  attr(:class, :string, default: "space-y-8")

  slot(:inner_block, required: true)

  def card_container(assigns) do
    ~H"""
    <div class={["mt-4", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["card", @class]}>
      <div class="card-body">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:title, :string, required: true)

  def card_title(assigns) do
    ~H"""
    <h2 class={["card-title mb-2 text-base text-black", @class]}><%= @title %></h2>
    """
  end

  attr(:rest, :global)

  slot(:inner_block, required: true)

  def banner(assigns) do
    ~H"""
    <div {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:page_meta, :map, required: true)
  attr(:title_suffix, :string)
  attr(:default, :map, required: true)

  def head_meta_tags(assigns) do
    page_meta =
      [:title, :description, :keyword, :image]
      |> Map.new(fn key -> {key, assigns.page_meta[key] || assigns.default[key]} end)

    assigns =
      assigns
      |> assign(:page_meta, page_meta)

    ~H"""
    <.live_title suffix={@title_suffix}><%= @page_meta.title %></.live_title>
    <meta name="title" property="og:title" content={@page_meta.title} />
    <meta name="description" property="og:description" content={@page_meta.description} />
    <meta name="keyword" content={@page_meta.keyword} />
    <meta property="og:image" content={normalize_image(@page_meta.image)} />
    <meta property="og:type" content="website" />
    <meta name="twitter:card" content="summary_large_image" />
    """
  end

  defp normalize_image(image) do
    cond do
      image == nil -> nil
      String.starts_with?(image, "http") -> image
      true -> CarrierWeb.Endpoint.url() <> image
    end
  end
end
