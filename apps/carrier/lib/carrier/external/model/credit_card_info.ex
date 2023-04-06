defmodule Carrier.External.Model.CreditCardInfo do
  @enforce_keys [:provider, :billing_key, :customer_key, :card_company, :card_number]
  defstruct @enforce_keys
end
