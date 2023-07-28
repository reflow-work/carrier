defmodule Carrier.Core.Browser do
  def screenshot(url) do
    with {:ok, session} <- start_session(),
         {:ok, screenshot} <- do_screenshot(session, url) do
      {:ok, screenshot}
    end
  end

  defp start_session() do
    Wallaby.start_session(
      capabilities: Wallaby.Chrome.default_capabilities() |> Map.merge(%{javascriptEnabled: true})
    )
  end

  defp do_screenshot(session, url) do
    session = session |> Wallaby.Browser.visit(url)

    body_element =
      session
      |> Wallaby.Browser.find(Wallaby.Query.css("body"))

    width =
      body_element
      |> Wallaby.Element.attr("scrollWidth")
      |> String.to_integer()

    height =
      body_element
      |> Wallaby.Element.attr("scrollHeight")
      |> String.to_integer()

    session =
      session
      |> Wallaby.Browser.resize_window(width, height)

    screenshot =
      session
      |> Wallaby.WebdriverClient.take_screenshot()

    {:ok, screenshot}
  after
    Wallaby.end_session(session)
  end
end
