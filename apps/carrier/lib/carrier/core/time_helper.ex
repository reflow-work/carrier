defmodule Carrier.Core.TimeHelper do
  def from!(opts) do
    hour = opts |> Keyword.get(:hour, 0)
    minute = opts |> Keyword.get(:minute, 0)
    second = opts |> Keyword.get(:second, 0)

    Time.new!(hour, minute, second)
  end

  def to_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    utc_offset = get_utc_offset(timezone)

    time |> Time.add(-utc_offset, :second)
  end

  def from_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    utc_offset = get_utc_offset(timezone)

    time |> Time.add(utc_offset, :second)
  end

  defp get_utc_offset(timezone) do
    timezone_info = Timex.Timezone.get(timezone)

    timezone_info.offset_utc
  end
end
