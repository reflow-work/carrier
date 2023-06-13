defmodule Carrier.Blog.MarkdownRenderer do
  alias Carrier.Blog.Highlighter

  def html(markdown) do
    markdown |> Earmark.as_html!() |> Highlighter.highlight()
  end
end
