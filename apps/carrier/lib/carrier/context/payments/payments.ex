defmodule Carrier.Payments do
  alias Carrier.Payments.{CreditCard, Payment}
  alias Carrier.External
  alias Carrier.TenantRepo
  alias Carrier.Core.Crypto

  defmacro __using__(_opts) do
    quote do
      alias Carrier.Payments
      alias Carrier.Payments.{CreditCard, Payment}
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

  def process_payment(%{
        org_id: org_id,
        credit_card_id: credit_card_id,
        amount: amount,
        currency: currency
      }) do
    with {:ok, %CreditCard{} = credit_card} <- fetch_credit_card(credit_card_id),
         {:ok, %Payment{} = payment} <-
           create_payment(%{
             org_id: org_id,
             credit_card_id: credit_card_id,
             amount: amount,
             currency: currency
           }),
         {:ok, %Payment{} = confirmed_payment} <-
           request_and_confirm_payment(payment, credit_card) do
      {:ok, confirmed_payment}
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

  defp fetch_credit_card(credit_card_id) do
    CreditCard.fetch(credit_card_id)
    |> TenantRepo.one()
    |> case do
      %CreditCard{} = credit_card ->
        {:ok, credit_card}

      nil ->
        {:error,
         {:resource_not_found,
          %{target: CreditCard, conditions: %{credit_card_id: credit_card_id}}}}
    end
  end

  defp create_payment(%{
         org_id: org_id,
         credit_card_id: credit_card_id,
         amount: amount,
         currency: currency
       }) do
    Payment.create(%{
      org_id: org_id,
      credit_card_id: credit_card_id,
      amount: amount,
      currency: currency
    })
    |> TenantRepo.insert()
  end

  # TODO: implement it
  defp request_and_confirm_payment(%Payment{} = payment, %CreditCard{} = credit_card) do
    with {:ok, %External.Model.PaymentInfo{} = payment_info} <- request_payment(credit_card, %{}),
         {:ok, %Payment{} = confirmed_payment} <-
           confirm_payment(payment, payment_info |> Map.from_struct()) do
      {:ok, confirmed_payment}
    end
  rescue
    error ->
      {:error, error}
  end

  # TODO: implement it
  defp request_payment(%CreditCard{provider: :toss_payments}, %{}) do
    {:ok, %External.Model.PaymentInfo{}}
  end

  # TODO: implement it
  defp confirm_payment(%Payment{} = payment, _params) do
    {:ok, payment}
  end
end
