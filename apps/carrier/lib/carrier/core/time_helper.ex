defmodule Carrier.Core.TimeHelper do
  alias Carrier.Core.TimezoneHelper

  def from!(opts) do
    hour = opts |> Keyword.get(:hour, 0)
    minute = opts |> Keyword.get(:minute, 0)
    second = opts |> Keyword.get(:second, 0)

    Time.new!(hour, minute, second)
  end

  def to_utc_time(%Time{} = zoned_time, timezone) when is_binary(timezone) do
    utc_offset_s = TimezoneHelper.get_utc_offset_s(timezone)

    zoned_time |> Time.add(-utc_offset_s, :second)
  end

  def from_utc_time(%Time{} = utc_time, timezone) when is_binary(timezone) do
    utc_offset_s = TimezoneHelper.get_utc_offset_s(timezone)

    utc_time |> Time.add(utc_offset_s, :second)
  end

  @day_s 60 * 60 * 24

  def calc_day_diff_to_utc_time(%Time{} = zoned_time, timezone) do
    utc_offset_s = TimezoneHelper.get_utc_offset_s(timezone)

    # ignore microseconds
    {zoned_time_s, _} = zoned_time |> Time.to_seconds_after_midnight()

    Integer.floor_div(zoned_time_s - utc_offset_s, @day_s)
  end

  def calc_day_diff_from_utc_time(%Time{} = utc_time, timezone) do
    utc_offset_s = TimezoneHelper.get_utc_offset_s(timezone)

    # ignore microseconds
    {utc_time_s, _} = utc_time |> Time.to_seconds_after_midnight()

    Integer.floor_div(utc_time_s + utc_offset_s, @day_s)
  end
end
