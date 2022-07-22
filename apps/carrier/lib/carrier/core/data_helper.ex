defmodule Carrier.Core.DataHelper do
  def transpose(list_of_lists) when is_list(list_of_lists) do
    list_of_lists |> List.zip() |> Enum.map(&Tuple.to_list/1)
  end

  def rows_to_map(columns, rows) do
    rows
    |> Enum.map(&(Enum.zip(columns, &1) |> Map.new()))
  end
end
