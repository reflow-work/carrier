defmodule CarrierWeb.Blog.PostLive.Show do
  use CarrierWeb, :live_view
  alias Carrier.Blog
  alias Carrier.Blog.MarkdownRenderer

  @impl true
  def mount(%{"language" => language, "slug" => slug}, _session, socket) do
    socket =
      socket
      |> assign(:language, language)
      |> assign(:slug, slug)
      |> load_post()

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
            <img class="border rounded-full" src={@post.author_thumbnail_url} width="20px" />
            <span class="ml-2"><%= @post.author %></span>
            <span class="mx-2 text-xs">|</span>
            <time><%= @post.date_created |> format_date() %></time>
          </div>
        </div>
      </div>

      <hr class="my-10" />

      <div class="mb-12 pt-4">
        <img :if={@post.cover_url} src={@post.cover_url} alt={@post.title} />
        <div class="mt-8"><%= @post.body |> MarkdownRenderer.html() |> raw() %></div>
      </div>
    </div>
    """
  end

  defp load_post(socket) do
    case Blog.fetch_post(socket.assigns.language, socket.assigns.slug) do
      {:ok, post} ->
        socket
        |> assign(:post, post)

      _ ->
        socket
        |> push_navigate(to: ~p"/blog/ko")
    end
  end
end
