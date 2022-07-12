defmodule Carrier.Core.DataHelper do
  def transpose(list_of_lists) when is_list(list_of_lists) do
    list_of_lists |> List.zip() |> Enum.map(&Tuple.to_list/1)
  end
end
