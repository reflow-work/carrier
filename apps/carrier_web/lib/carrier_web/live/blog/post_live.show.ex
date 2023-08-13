defmodule CarrierWeb.Blog.PostLive.Show do
  use CarrierWeb, :live_view
  alias Carrier.Blog
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
    <div class="max-w-7xl px-4 md:px-8 mx-auto">
      <div class="my-8">
        <div>
          <h1 class="text-4xl font-bold"><%= @post.title %></h1>
          <p class="mt-2"><%= @post.description %></p>

          <div class="mt-4 text-sm text-description flex items-center">
            <img class="border rounded-full" src={~p"/images/avatar-1.png"} width="20px" />
            <span class="ml-2">Wonny</span>
            <span class="mx-2 text-xs">|</span>
            <time><%= @post.date_created %></time>
          </div>
        </div>
      </div>

      <hr class="my-10" />

      <div class="mb-12 pt-4">
        <%= if @post.cover_url do %>
          <img src={@post.cover_url} alt={@post.title} />
        <% end %>
        <div class="mt-8"><%= @post.body |> MarkdownRenderer.html() |> raw() %></div>

        <hr class="my-10" />

        <%= if @post.tags do %>
          <div class="mt-2 text-sm">
            Tags:
            <%= for tag <- @post.tags do %>
              <.link navigate={~p"/blog?tag=#{tag}"}>
                <span class="mr-2 tag">#<%= tag %></span>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>
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
