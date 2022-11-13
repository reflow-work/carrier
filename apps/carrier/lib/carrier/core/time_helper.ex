defmodule Carrier.Core.TimeHelper do
  alias Carrier.Core.TimezoneHelper

  def from!(opts) do
    hour = opts |> Keyword.get(:hour, 0)
    minute = opts |> Keyword.get(:minute, 0)
    second = opts |> Keyword.get(:second, 0)

    Time.new!(hour, minute, second)
  end

  def to_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    utc_offset = TimezoneHelper.get_utc_offset_s(timezone)

    time |> Time.add(-utc_offset, :second)
  end

  def from_utc_time(%Time{} = time, timezone) when is_binary(timezone) do
    utc_offset = TimezoneHelper.get_utc_offset_s(timezone)

    time |> Time.add(utc_offset, :second)
  end
end
