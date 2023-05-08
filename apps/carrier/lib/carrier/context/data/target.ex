defmodule Carrier.Data.Target do
  @callback blocks_to_report_message(data_target :: map(), blocks :: list()) ::
              {:ok, map() | list()}
  @callback send_report_message(data_target :: map(), report_message :: map() | list()) ::
              {:ok, any()}
end
