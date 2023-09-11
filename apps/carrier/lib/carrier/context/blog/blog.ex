defmodule Carrier.Blog do
  use Carrier.Core.Cache
  alias Carrier.Blog.Post

  @decorate cacheable(
              cache: Cache.Local,
              key: {Blog, :list_posts_by_language, [language, posts_path]},
              opts: cache_opts()
            )
  @spec list_posts_by_language(language :: String.t()) :: {:ok, [Post.t()]}
  def list_posts_by_language(language, posts_path \\ posts_path()) do
    list_posts(posts_path)
    |> then(fn {:ok, posts} -> posts |> Enum.group_by(& &1.language) end)
    |> Map.get(language, [])
    |> then(&{:ok, &1})
  end

  @spec list_posts() :: [Post.t()]
  def list_posts(posts_path \\ posts_path()) do
    list_post_paths(posts_path)
    |> Enum.map(&read_post/1)
    |> Enum.sort_by(fn %Post{date_created: date_created} -> date_created end, {:desc, Date})
    |> then(&{:ok, &1})
  end

  @decorate cacheable(
              cache: Cache.Local,
              key: {Blog, :fetch_post, [language, slug, posts_path]},
              opts: cache_opts()
            )
  @spec fetch_post(language :: String.t(), slug :: String.t()) :: {:ok, %Post{}} | :error
  def fetch_post(language, slug, posts_path \\ posts_path()) do
    with {:ok, posts} <- list_posts_by_language(language, posts_path) do
      posts
      |> Enum.find(fn %Post{slug: post_slug} -> post_slug == slug end)
      |> case do
        %Post{} = post -> {:ok, post}
        nil -> {:error, :resource_not_found}
      end
    end
  end

  defp list_post_paths(posts_path) do
    (posts_path <> "/**/*.{md,livemd}")
    |> Path.wildcard()
  end

  defp read_post(post_path) do
    post_meta = extract_post_meta(post_path)

    post_path
    |> File.read!()
    |> parse_post(post_meta)
  end

  defp parse_post(raw_post, %{language: language, slug: slug, date_created: date_created}) do
    [meta_str, body] =
      raw_post
      |> String.split("---", parts: 2, trim: true)

    {meta_map, _binding} = meta_str |> Code.eval_string()

    title = meta_map |> Map.fetch!(:title)
    author = meta_map |> Map.fetch!(:author)
    author_thumbnail_url = meta_map |> Map.fetch!(:author_thumbnail_url)
    category = meta_map |> Map.fetch!(:category)

    %Post{
      title: title,
      description: meta_map[:description],
      language: language,
      author: author,
      author_thumbnail_url: author_thumbnail_url,
      category: category,
      slug: slug,
      body: body,
      date_created: date_created,
      cover_url: meta_map[:cover_url],
      tags: meta_map[:tags],
      cta: struct(Post.CTA, meta_map[:cta])
    }
  end

  defp extract_post_meta(post_path) do
    %{"language" => language, "date_created" => date_created_str, "slug" => slug} =
      Regex.named_captures(
        ~r/\/(?<language>[^\/]+)\/[^\/]+\/(?<date_created>\d{8})_(?<slug>.+)\.(md|livemd)$/,
        post_path
      )

    date_created = date_created_str |> Timex.parse!("{YYYY}{0M}{0D}") |> NaiveDateTime.to_date()

    %{language: language, slug: slug, date_created: date_created}
  end

  defp posts_path() do
    Application.app_dir(:carrier, "priv/posts")
  end

  case Mix.env() do
    :dev -> defp cache_opts(), do: [ttl: 0]
    _ -> defp cache_opts(), do: [ttl: :infinity]
  end
end
