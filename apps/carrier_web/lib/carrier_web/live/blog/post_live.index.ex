defmodule CarrierWeb.Blog.PostLive.Index do
  use CarrierWeb, :live_view
  alias Carrier.Blog
  alias Carrier.Blog.Post

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:posts, Blog.list_posts())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-baseline">
      <h1 class="text-2xl mb-4 font-bold">Posts</h1>
    </div>

    <div>
      <%= for %Post{} = post <- @posts do %>
        <.link navigate={~p"/blog/#{post}"}>
          <article class="py-4 border-b-2 cursor-pointer">
            <h2 class="text-xl"><%= post.title %></h2>
            <%= if post.description do %>
              <p class="mt-2"><%= post.description %></p>
            <% end %>
            <div class="mt-6">
              Date created: <time><%= post.date_created %></time>
            </div>
          </article>
        </.link>
      <% end %>
    </div>
    """
  end
end
