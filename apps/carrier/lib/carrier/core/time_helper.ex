defmodule Carrier.Core.TimeHelper do
  def from!(opts) do
    hour = opts |> Keyword.get(:hour, 0)
    minute = opts |> Keyword.get(:minute, 0)
    second = opts |> Keyword.get(:second, 0)

    Time.new!(hour, minute, second)
  end

  def to_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    timezone_info = Timex.Timezone.get(timezone)

    time |> Time.add(-timezone_info.offset_utc, :second)
  end

  def from_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    timezone_info = Timex.Timezone.get(timezone)

    time |> Time.add(timezone_info.offset_utc, :second)
  end
end
