defmodule Carrier.External.Model.PaymentInfo do
  @enforce_keys [:provider, :provider_key, :item, :payload]
  defstruct @enforce_keys ++ [:confirmed_at]
end
