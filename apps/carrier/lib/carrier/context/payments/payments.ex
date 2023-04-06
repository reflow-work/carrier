defmodule Carrier.Payments do
  alias Carrier.Payments.CreditCard
  alias Carrier.TenantRepo

  defmacro __using__(_opts) do
    quote do
      alias Carrier.Payments
      alias Carrier.Payments.CreditCard
    end
  end

  def create_credit_card(params) do
    CreditCard.create(params)
    |> TenantRepo.insert()
  end
end
