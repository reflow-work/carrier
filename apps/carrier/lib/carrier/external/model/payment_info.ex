defmodule Carrier.External.Model.PaymentInfo do
  @enforce_keys [:provider, :provider_key, :payload]
  defstruct @enforce_keys ++ [:confirmed_at]
end
