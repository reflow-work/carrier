defmodule Carrier.Data.Block do
  def text(text, style \\ :normal) when style in [:normal, :bold] do
    %{
      type: :text,
      text: text,
      style: style
    }
  end

  def link(text, url) do
    %{
      type: :link,
      text: text,
      url: url
    }
  end

  def image(title, image_url, alt_text) do
    %{
      type: :image,
      title: title,
      image_url: image_url,
      alt_text: alt_text
    }
  end

  def button(text, url) do
    %{
      type: :button,
      text: text,
      url: url
    }
  end
end
