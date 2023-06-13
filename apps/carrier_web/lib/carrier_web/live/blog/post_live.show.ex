defmodule CarrierWeb.Blog.PostLive.Show do
  use CarrierWeb, :live_view
  alias Carrier.Blog
  alias Carrier.Blog.Post
  alias Carrier.Blog.MarkdownRenderer

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    socket =
      socket
      |> load_post(slug)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pb-4">
      <div class="prose">
        <h1><%= @post.title %></h1>
        <p><%= @post.description %></p>
        <div><time>Date created: <%= @post.date_created %></time></div>
      </div>
      <%= if @post.tags do %>
        <div class="mt-2">
          <%= for tag <- @post.tags do %>
            <.link navigate={~p"/blog?tag=#{tag}"}>
              <span class="mr-2 tag">#<%= tag %></span>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    <hr class="prose" />
    <div class="prose pt-4">
      <%= if @post.cover_url do %>
        <img src={@post.cover_url} alt={@post.title} class="w-full" />
      <% end %>
      <%= @post.body |> MarkdownRenderer.html() |> raw() %>
    </div>
    """
  end

  defp load_post(socket, slug) do
    case Blog.fetch_post(slug) do
      {:ok, post} ->
        socket
        |> assign(:post, post)

      _ ->
        socket
        |> push_navigate(to: ~p"/blog")
    end
  end
end
