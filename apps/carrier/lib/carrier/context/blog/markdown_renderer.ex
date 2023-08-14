defmodule Carrier.Blog.MarkdownRenderer do
  alias Carrier.Blog.{Highlighter, HTML}

  def html(markdown) do
    markdown |> Earmark.as_html!() |> Highlighter.highlight()
  end

  def plain_text(markdown) do
    markdown |> html() |> HTML.strip_tags()
  end
end
