defmodule Carrier.External.SlackAPI.Format do
  alias Carrier.Core.StringHelper

  def html_to_mrkdwn(html) do
    document = html |> Floki.parse_document!()

    nodes_to_mrkdwn(document, "")
  end

  defp nodes_to_mrkdwn([node | rest_nodes], acc) do
    nodes_to_mrkdwn(rest_nodes, acc <> interpret_node(node))
  end

  defp nodes_to_mrkdwn([], acc) do
    acc
  end

  defp interpret_node({"div", _attrs, children}) do
    missing_new_line =
      case children |> List.last() do
        {"br", _attrs, _children} -> ""
        _ -> "\n"
      end

    nodes_to_mrkdwn(children, "") <> missing_new_line
  end

  defp interpret_node({"strong", _attrs, children}) do
    wrap(nodes_to_mrkdwn(children, ""), &"*#{&1}*")
  end

  defp interpret_node({"a", _attrs, children} = node) do
    href = node |> Floki.attribute("href")

    "<#{href}|#{nodes_to_mrkdwn(children, "")}>"
  end

  defp interpret_node({"del", _attrs, children}) do
    wrap(nodes_to_mrkdwn(children, ""), &"~#{&1}~")
  end

  defp interpret_node({"em", _attrs, children}) do
    wrap(nodes_to_mrkdwn(children, ""), &"_#{&1}_")
  end

  defp interpret_node({"br", _attrs, _children}) do
    "\n"
  end

  defp interpret_node({"pre", _attrs, children}) do
    "```#{nodes_to_mrkdwn(children, "")}```"
  end

  defp interpret_node({"ul", _attrs, children}) do
    nodes_to_mrkdwn(children, "")
  end

  defp interpret_node({"li", _attrs, children}) do
    "• #{nodes_to_mrkdwn(children, "")}\n"
  end

  defp interpret_node(text) when is_binary(text) do
    text
  end

  defp interpret_node(_) do
    ""
  end

  defp wrap(inner_text, fun) do
    {leading_spaces, inner_text} = inner_text |> StringHelper.split_leading(" ")
    {trailing_spaces, inner_text} = inner_text |> StringHelper.split_trailing(" ")

    (leading_spaces <> fun.(inner_text) <> trailing_spaces)
    |> extract_new_line_to_trail()
  end

  defp extract_new_line_to_trail(str) do
    new_line_count = str |> String.graphemes() |> Enum.filter(&(&1 == "\n")) |> Enum.count()

    str
    |> String.replace("\n", "")
    |> Kernel.<>(String.duplicate("\n", new_line_count))
  end
end
