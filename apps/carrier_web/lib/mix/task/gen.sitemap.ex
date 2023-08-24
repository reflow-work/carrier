defmodule Mix.Tasks.Gen.Sitemap do
  use Mix.Task
  alias Carrier.Blog
  alias Carrier.Blog.Post

  @impl Mix.Task
  def run(_args) do
    url = "https://reflow.work"

    config = [
      store: Sitemapper.FileStore,
      store_config: [
        path: "#{:code.priv_dir(:carrier_web)}/static"
      ],
      sitemap_url: url,
      gzip: false
    ]

    sitemaps =
      ["/", "/login", "/blog/ko", "/blog/en"]
      |> Enum.map(fn path ->
        %Sitemapper.URL{
          loc: "#{url}#{path}",
          changefreq: :weekly
        }
      end)

    post_sitemaps =
      Blog.list_posts()
      |> then(fn {:ok, posts} ->
        posts
        |> Enum.map(fn %Post{language: language, slug: slug, date_created: date_created} ->
          %Sitemapper.URL{
            loc: "#{url}/blog/#{language}/#{slug}",
            changefreq: :daily,
            lastmod: date_created
          }
        end)
      end)

    (sitemaps ++ post_sitemaps)
    |> Sitemapper.generate(config)
    |> Sitemapper.persist(config)
    |> Sitemapper.ping(config)
    |> Stream.run()

    :ok
  end
end
