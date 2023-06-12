defmodule Carrier.Core.WeekdayHelper do
  alias Carrier.Core.TimeHelper

  def add(weekday, days) do
    rem(weekday + days, 7)
    |> case do
      weekday when weekday < 1 -> weekday + 7
      weekday -> weekday
    end
  end

  def to_utc_weekday(zoned_weekday, %Time{} = zoned_time, timezone) do
    add(zoned_weekday, TimeHelper.calc_day_diff_to_utc_time(zoned_time, timezone))
  end

  def from_utc_weekday(utc_weekday, %Time{} = utc_time, timezone) do
    add(utc_weekday, TimeHelper.calc_day_diff_from_utc_time(utc_time, timezone))
  end
end
