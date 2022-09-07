defmodule Carrier.Core.TimeHelper do
  def from!(opts) do
    hour = opts |> Keyword.get(:hour, 0)
    minute = opts |> Keyword.get(:minute, 0)
    second = opts |> Keyword.get(:second, 0)

    Time.new!(hour, minute, second)
  end
end
