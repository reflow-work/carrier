defmodule Carrier.Core.DateTimeHelper do
  def get_next_with_time(%DateTime{utc_offset: 0} = utc_datetime, %Time{} = utc_time) do
    date = utc_datetime |> DateTime.to_date()
    utc_datetime_with_time = DateTime.new!(date, utc_time, utc_datetime.time_zone)

    case DateTime.compare(utc_datetime_with_time, utc_datetime) do
      :gt -> utc_datetime_with_time
      _ -> utc_datetime_with_time |> Timex.shift(days: 1)
    end
  end
end
