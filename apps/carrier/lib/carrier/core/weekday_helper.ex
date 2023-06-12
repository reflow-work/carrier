defmodule Carrier.Core.WeekdayHelper do
  def add(weekday, days) do
    rem(weekday + days, 7)
    |> case do
      weekday when weekday < 1 -> weekday + 7
      weekday -> weekday
    end
  end
end
