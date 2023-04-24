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

  # Assumption: There is only one CreditCard per Org.
  def fetch_default_credit_card() do
    CreditCard.fetch_default()
    |> TenantRepo.one()
    |> case do
      %CreditCard{} = credit_card ->
        {:ok, credit_card}

      nil ->
        {:error, {:resource_not_found, %{target: CreditCard, conditions: %{}}}}
    end
  end

  def process_payment(%{
        org_id: org_id,
        amount: amount,
        currency: currency,
        order_id: order_id,
        order_name: order_name,
        customer_email: customer_email,
        customer_name: customer_name
      }) do
    with {:ok, %CreditCard{} = credit_card} <- fetch_default_credit_card(),
         {:ok, %Payment{} = payment} <-
           create_payment(%{
             org_id: org_id,
             credit_card_id: credit_card.id,
             amount: amount,
             currency: currency
           }),
         {:ok, %Payment{} = confirmed_payment} <-
           request_and_confirm_payment(payment, credit_card, %{
             order_id: order_id,
             order_name: order_name,
             customer_email: customer_email,
             customer_name: customer_name
           }) do
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

  defp request_credit_card_info(:toss_payments, %{
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

  defp request_and_confirm_payment(%Payment{} = payment, %CreditCard{} = credit_card, %{
         order_id: order_id,
         order_name: order_name,
         customer_email: customer_email,
         customer_name: customer_name
       }) do
    request_payment(payment, credit_card, %{
      order_id: order_id,
      order_name: order_name,
      customer_email: customer_email,
      customer_name: customer_name
    })
    |> case do
      {:ok, %External.Model.PaymentInfo{} = payment_info} ->
        with {:ok, %Payment{} = confirmed_payment} <-
               confirm_payment(payment, payment_info |> Map.from_struct()) do
          {:ok, confirmed_payment}
        end

      {:error, reason} ->
        with {:ok, %Payment{} = failed_payment} <-
               fail_payment(payment, reason) do
          {:error, failed_payment}
        end
    end
  rescue
    error ->
      with {:ok, %Payment{} = failed_payment} <-
             fail_payment(payment, %{error: inspect(error)}) do
        {:error, failed_payment}
      end
  end

  defp request_payment(
         %Payment{amount: amount, currency: :KRW},
         %CreditCard{
           provider: :toss_payments,
           billing_key: billing_key,
           customer_key: customer_key
         },
         %{
           order_id: order_id,
           order_name: order_name,
           customer_email: customer_email,
           customer_name: customer_name
         }
       ) do
    with {:ok, %External.Model.PaymentInfo{} = payment_info} <-
           External.TossPayments.bill(%{
             billing_key: billing_key,
             amount: amount,
             customer_key: customer_key,
             order_id: order_id,
             order_name: order_name,
             customer_email: customer_email,
             customer_name: customer_name
           }) do
      {:ok, payment_info}
    end
  end

  defp confirm_payment(%Payment{} = payment, %{
         confirmed_at: confirmed_at,
         provider: provider,
         provider_key: provider_key,
         payload: payload
       }) do
    payment
    |> Payment.confirm(%{
      confirmed_at: confirmed_at,
      provider: provider,
      provider_key: provider_key,
      payload: payload
    })
    |> TenantRepo.update()
  end

  defp fail_payment(%Payment{} = payment, reason) do
    payment
    |> Payment.fail(%{
      failed_at: DateTime.utc_now(),
      payload: reason
    })
    |> TenantRepo.update()
  end
end
