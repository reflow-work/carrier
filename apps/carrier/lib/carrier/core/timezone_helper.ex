defmodule Carrier.Core.TimezoneHelper do
  @default_timzone "Etc/UTC"

  def put_timezone(timezone) when is_binary(timezone) do
    Process.put({__MODULE__, :timezone}, timezone)
  end

  def apply_timezone(%DateTime{} = datetime) do
    timezone = Process.get({__MODULE__, :timezone})

    valid_timezone = safe_timezone(timezone)

    datetime
    |> DateTime.shift_zone!(valid_timezone)
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
end
