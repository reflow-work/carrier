defmodule Carrier.Core.StringHelper do
  def split_leading(string, match) do
    match_size = byte_size(match)

    do_split_leading(string, match, match_size, "")
  end

  def split_trailing(string, match) do
    match_size = byte_size(match)
    rest_size = byte_size(string) - match_size

    do_split_trailing(string, match, match_size, rest_size, "")
  end

  defp do_split_leading(string, match, match_size, acc) do
    case string do
      <<matched::size(match_size)-binary, rest::binary>> when matched == match ->
        do_split_leading(rest, match, match_size, acc <> matched)

      _ ->
        {acc, string}
    end
  end

  defp do_split_trailing(string, match, match_size, rest_size, acc) do
    case string do
      <<rest::size(rest_size)-binary, matched::binary>> when matched == match ->
        do_split_trailing(rest, match, match_size, rest_size - match_size, acc <> matched)

      _ ->
        {acc, string}
    end
  end
end
