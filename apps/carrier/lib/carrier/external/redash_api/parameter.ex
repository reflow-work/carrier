defmodule Carrier.External.RedashAPI.Parameter do
  alias Carrier.Data.Source.Redash.Parameter

  def generate_value(%Parameter{type: type, value: value}, utc_datetime, timezone)
      when type in [
             "date",
             "datetime-local",
             "datetime-with-seconds",
             "date-range",
             "datetime-range",
             "datetime-range-with-seconds"
           ] do
    datetime = utc_datetime |> DateTime.shift_zone!(timezone)

    convert_value(value, datetime)
    |> format(type)
  end

  def generate_value(%Parameter{type: _, value: value}, _, _) do
    value
  end

  defp convert_value("d_now", datetime) do
    datetime
  end

  defp convert_value("d_yesterday", datetime) do
    datetime |> Timex.shift(days: -1)
  end

  defp convert_value("d_this_week", datetime) do
    start_value = Timex.beginning_of_week(datetime, :sun)
    end_value = Timex.end_of_week(datetime, :sun)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_this_month", datetime) do
    start_value = Timex.beginning_of_month(datetime)
    end_value = Timex.end_of_month(datetime)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_this_year", datetime) do
    start_value = Timex.beginning_of_year(datetime)
    end_value = Timex.end_of_year(datetime)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_week", datetime) do
    datetime = datetime |> Timex.shift(weeks: -1)
    start_value = Timex.beginning_of_week(datetime, :sun)
    end_value = Timex.end_of_week(datetime, :sun)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_month", datetime) do
    datetime = datetime |> Timex.shift(months: -1)
    start_value = Timex.beginning_of_month(datetime)
    end_value = Timex.end_of_month(datetime)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_year", datetime) do
    datetime = datetime |> Timex.shift(years: -1)
    start_value = Timex.beginning_of_year(datetime)
    end_value = Timex.end_of_year(datetime)

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_7_days", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(days: -7) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_14_days", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(days: -14) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_30_days", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(days: -30) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_60_days", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(days: -60) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_90_days", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(days: -90) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value("d_last_12_months", datetime) do
    end_value = datetime |> Timex.end_of_day()
    start_value = datetime |> Timex.shift(months: -12) |> Timex.beginning_of_day()

    %{
      "start" => start_value,
      "end" => end_value
    }
  end

  defp convert_value(value, _datetime) do
    value
  end

  defp format(%DateTime{} = datetime, type) do
    Timex.format!(datetime, type_to_format(type))
  end

  defp format(%{} = map, type) do
    map
    |> Map.new(fn {key, value} -> {key, format(value, type)} end)
  end

  defp format(value, _type) do
    value
  end

  defp type_to_format("date"), do: "{YYYY}-{0M}-{0D}"
  defp type_to_format("date-range"), do: "{YYYY}-{0M}-{0D}"
  defp type_to_format("datetime-local"), do: "{YYYY}-{0M}-{0D} {h24}:{m}"
  defp type_to_format("datetime-range"), do: "{YYYY}-{0M}-{0D} {h24}:{m}"
  defp type_to_format("datetime-with-seconds"), do: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
  defp type_to_format("datetime-range-with-seconds"), do: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
end
