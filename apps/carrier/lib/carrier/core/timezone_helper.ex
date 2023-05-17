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

  def safe_timezone(timezone) do
    case Timex.is_valid_timezone?(timezone) do
      true -> timezone
      false -> @default_timzone
    end
  rescue
    _ -> @default_timzone
  end

  def get_utc_offset_s(timezone) do
    timezone_info = Timex.Timezone.get(timezone)

    timezone_info.offset_utc
  end

  def timezone_key() do
    {__MODULE__, :timezone}
  end
end
