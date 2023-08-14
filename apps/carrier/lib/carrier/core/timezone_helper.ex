defmodule Carrier.Core.TimezoneHelper do
  @default_timzone "Etc/UTC"

  def get_timezone() do
    Process.get(timezone_key()) || @default_timzone
  end

  def put_timezone(timezone) when is_binary(timezone) do
    Process.put(timezone_key(), safe_timezone(timezone))
  end

  def apply_timezone(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!(get_timezone())
  end

  def apply_timezone(%Date{} = date) do
    date
  end

  def safe_timezone(timezone) do
    case Timex.is_valid_timezone?(timezone) do
      true -> timezone
      false -> @default_timzone
    end
  rescue
    _ -> @default_timzone
  end

  def get_utc_offset_s(timezone) do
    timezone_info = get_timezone_info(timezone)

    timezone_info.offset_utc
  end

  def safe_format(timezone) do
    case get_timezone_info(timezone) do
      {:error, _} ->
        "-"

      timezone_info ->
        formatted_offset = Timex.TimezoneInfo.format_offset(timezone_info)

        "#{timezone_info.abbreviation}(#{formatted_offset})"
    end
  end

  def timezone_key() do
    {__MODULE__, :timezone}
  end

  defp get_timezone_info(timezone) do
    Timex.Timezone.get(timezone)
  end
end
