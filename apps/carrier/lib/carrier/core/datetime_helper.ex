defmodule Carrier.Core.DateTimeHelper do
  import Kernel, except: [max: 2, min: 2]
  alias Carrier.Core.{Cldr, OkTuple}

  def safe_format(maybe_datetime, opts \\ []) do
    format = opts |> Keyword.get(:format, :short)
    fallback = opts |> Keyword.get(:fallback, "-")

    Cldr.DateTime.to_string(maybe_datetime, format: format)
    |> OkTuple.unwrap(fallback)
  end

  def get_next_with_time(%DateTime{utc_offset: 0} = utc_datetime, %Time{} = utc_time) do
    date = utc_datetime |> DateTime.to_date()
    utc_datetime_with_time = DateTime.new!(date, utc_time, utc_datetime.time_zone)

    case DateTime.compare(utc_datetime_with_time, utc_datetime) do
      :gt -> utc_datetime_with_time
      _ -> utc_datetime_with_time |> Timex.shift(days: 1)
    end
  end

  def calc_next_with_weekday_time(%DateTime{} = utc_datetime, utc_weekday, %Time{} = utc_time) do
    weekday = utc_datetime |> Timex.weekday()
    time = utc_datetime |> DateTime.to_time()

    case {weekday - utc_weekday, Time.compare(time, utc_time)} do
      {weekday_diff, time_compare}
      when weekday_diff < 0 or (weekday_diff == 0 and time_compare == :lt) ->
        utc_datetime |> Timex.shift(days: -weekday_diff) |> Timex.set(time: utc_time)

      {weekday_diff, _} ->
        utc_datetime |> Timex.shift(days: 7 - weekday_diff) |> Timex.set(time: utc_time)
    end
  end

  def calc_next(%DateTime{month: month, day: day} = start_datetime, cycle, nth) do
    shift_option =
      case cycle do
        :monthly -> :months
        :yearly -> :years
      end

    next = start_datetime |> Timex.shift([{shift_option, nth}])

    # https://github.com/bitwalker/timex/issues/739
    case month == 2 and day == 29 and cycle == :yearly and not Timex.is_leap?(next) do
      true -> next |> Timex.shift(days: -1)
      false -> next
    end
  end

  def calc_next_hourly(%DateTime{} = datetime) do
    datetime
    |> truncate(:hour)
    |> Timex.shift(hours: 1)
  end

  def max(%DateTime{} = datetime1, %DateTime{} = datetime2) do
    case DateTime.compare(datetime1, datetime2) do
      :lt -> datetime2
      _ -> datetime1
    end
  end

  def min(%DateTime{} = datetime1, %DateTime{} = datetime2) do
    case DateTime.compare(datetime1, datetime2) do
      :gt -> datetime2
      _ -> datetime1
    end
  end

  def truncate(%DateTime{} = datetime, precision)
      when precision in [:microsecond, :millisecond, :second] do
    datetime |> DateTime.truncate(precision)
  end

  def truncate(%DateTime{} = datetime, :minute) do
    datetime
    |> truncate(:second)
    |> Map.put(:second, 0)
  end

  def truncate(%DateTime{} = datetime, :hour) do
    datetime
    |> truncate(:minute)
    |> Map.put(:minute, 0)
  end
end
