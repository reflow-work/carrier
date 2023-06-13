defmodule Carrier.Core.WeekdayHelper do
  alias Carrier.Core.{Cldr, TimeHelper}

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

  def safe_format_weekday(weekday, format \\ :abbreviated) when format in [:wide, :abbreviated] do
    type =
      case format do
        :wide -> :day_of_week_names
        :abbreviated -> :abbreviated_day_of_week_names
      end

    Cldr.Calendar.strftime_options!(Cldr.get_locale())[type].(weekday)
  end
end
