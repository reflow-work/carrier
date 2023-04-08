defmodule Carrier.Billing do
  defmacro __using__([]) do
    quote do
      alias Carrier.Billing
      alias Carrier.Billing.Plan
    end
  end
end
