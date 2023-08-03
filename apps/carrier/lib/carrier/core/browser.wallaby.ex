# defmodule Carrier.Core.Browser.Wallaby do
#   def screenshot(url) do
#     with {:ok, session} <- start_session(),
#          {:ok, screenshot} <- do_screenshot(session, url) do
#       {:ok, screenshot}
#     end
#   end

#   defp start_session() do
#     Wallaby.start_session(
#       capabilities: Wallaby.Chrome.default_capabilities() |> Map.merge(%{javascriptEnabled: true})
#     )
#   end

#   defp do_screenshot(session, url) do
#     session = session |> Wallaby.Browser.visit(url)

#     screenshot =
#       run_after_ready(session, fn ->
#         body_element =
#           session
#           |> Wallaby.Browser.find(Wallaby.Query.css("body"))

#         width =
#           body_element
#           |> Wallaby.Element.attr("scrollWidth")
#           |> String.to_integer()

#         height =
#           body_element
#           |> Wallaby.Element.attr("scrollHeight")
#           |> String.to_integer()

#         session =
#           session
#           |> Wallaby.Browser.resize_window(width, height)

#         _screenshot =
#           session
#           |> Wallaby.WebdriverClient.take_screenshot()
#       end)

#     {:ok, screenshot}
#   after
#     Wallaby.end_session(session)
#   end

#   defp run_after_ready(session, fun) do
#     Process.sleep(:timer.seconds(1))

#     case Wallaby.WebdriverClient.execute_script(session, "return document.readyState", []) do
#       {:ok, "complete"} ->
#         fun.()

#       _ ->
#         run_after_ready(session, fun)
#     end
#   end
# end
