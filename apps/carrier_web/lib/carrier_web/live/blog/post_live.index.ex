defmodule CarrierWeb.Blog.PostLive.Index do
  use CarrierWeb, :live_view
  alias Carrier.Blog
  alias Carrier.Blog.MarkdownRenderer

  @impl true
  def mount(%{"language" => language}, _session, socket) do
    socket =
      socket
      |> assign(:language, language)
      |> stream_configure(:posts, dom_id: &"post-#{&1.slug}")
      |> load_posts()

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> push_navigate(to: ~p"/blog/ko", replace: true)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl px-4 md:px-8 mx-auto">
      <div class="my-8">
        <div>
          <h1 class="text-4xl font-bold">Blog</h1>
        </div>
      </div>

      <div id="posts" class="my-10 divide-y" phx-update="stream">
        <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="py-6">
          <.link navigate={~p"/blog/#{post.language}/#{post}"}>
            <article class="py-4 cursor-pointer">
              <h2 class="text-xl font-bold"><%= post.title %></h2>
              <p class="mt-2">
                <%= if post.description do %>
                  <span class="text-sm mt-2 font-bold"><%= post.description %></span>
                <% end %>
                <%= if post.body do %>
                  <span class="text-sm line-clamp-2 mt-2">
                    <%= post.body |> MarkdownRenderer.plain_text() %>
                  </span>
                <% end %>
              </p>
              <div class="mt-4 text-sm text-description flex items-center">
                <img class="border rounded-full" src={post.author_thumbnail_url} width="20px" />
                <span class="ml-2"><%= post.author %></span>
                <span class="mx-2 text-xs">|</span>
                <time><%= post.date_created |> format_date() %></time>
              </div>
            </article>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp load_posts(socket) do
    case Blog.list_posts_by_language(socket.assigns.language) do
      {:ok, posts} -> socket |> stream(:posts, posts)
      _ -> socket
    end
  end
end
