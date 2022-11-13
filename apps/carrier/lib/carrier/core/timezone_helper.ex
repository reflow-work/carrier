defmodule Carrier.Core.TimezoneHelper do
  def get_utc_offset_s(timezone) do
    timezone_info = Timex.Timezone.get(timezone)

    timezone_info.offset_utc
  end
end
