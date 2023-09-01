defmodule Carrier.Blog.Post do
  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          language: String.t(),
          author: String.t(),
          author_thumbnail_url: String.t(),
          category: String.t(),
          slug: String.t(),
          body: String.t(),
          date_created: Date.t(),
          cover_url: String.t(),
          tags: [String.t()],
          cta: map()
        }

  defmodule CTA do
    @enforce_keys [:text, :button_text, :button_url]

    defstruct @enforce_keys
  end

  @derive {Phoenix.Param, key: :slug}
  @enforce_keys [
    :title,
    :description,
    :language,
    :author,
    :author_thumbnail_url,
    :category,
    :slug,
    :body,
    :date_created,
    :cover_url,
    :tags,
    :cta
  ]
  defstruct @enforce_keys

  def is_category(%__MODULE__{category: post_category}, category) do
    post_category == category
  end

  def has_tag(%__MODULE__{tags: tags}, tag) when is_list(tags) do
    tag in tags
  end

  def has_tag(%__MODULE__{tags: nil}, _tag) do
    false
  end
end
