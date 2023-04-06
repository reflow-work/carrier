defmodule Carrier.Payments do
  alias Carrier.Payments.CreditCard
  alias Carrier.External
  alias Carrier.TenantRepo
  alias Carrier.Core.Crypto

  defmacro __using__(_opts) do
    quote do
      alias Carrier.Payments
      alias Carrier.Payments.CreditCard
    end
  end

  def create_credit_card(:toss_payments, %{
        org_id: org_id,
        customer_key: customer_key,
        auth_key: auth_key
      }) do
    with {:ok, %External.Model.CreditCardInfo{} = credit_card_params} <-
           request_credit_card_info(:toss_payments, %{
             org_id: org_id,
             customer_key: customer_key,
             auth_key: auth_key
           }),
         credit_card_params = credit_card_params |> Map.from_struct() |> Map.put(:org_id, org_id),
         {:ok, %CreditCard{} = credit_card} <- do_create_credit_card(credit_card_params) do
      {:ok, credit_card}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_create_credit_card(params) do
    CreditCard.create(params)
    |> TenantRepo.insert()
  end

  def request_credit_card_info(:toss_payments, %{
        org_id: org_id,
        customer_key: customer_key,
        auth_key: auth_key
      }) do
    with ^customer_key = Crypto.obfuscate(org_id),
         {:ok, %External.Model.CreditCardInfo{customer_key: ^customer_key} = credit_card_params} <-
           External.TossPayments.issue_billing_auth(auth_key, customer_key) do
      {:ok, credit_card_params}
    end
  end
end
