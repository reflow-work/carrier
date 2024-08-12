defmodule Carrier.Payments do
  require Logger
  alias Carrier.Payments.{CreditCard, Payment}
  alias Carrier.External
  alias Carrier.Repo
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
    |> Repo.one()
    |> case do
      %CreditCard{} = credit_card ->
        {:ok, credit_card}

      nil ->
        {:error, {:resource_not_found, %{target: CreditCard, conditions: %{}}}}
    end
  end

  def create_payment(%{org_id: org_id, amount: amount, currency: currency}) do
    Payment.create(%{org_id: org_id, amount: amount, currency: currency})
    |> Repo.insert()
  end

  def process_payment(payment_id, %{
        order_id: order_id,
        order_name: order_name,
        customer_email: customer_email,
        customer_name: customer_name
      }) do
    with {:ok, %CreditCard{} = credit_card} <- fetch_default_credit_card(),
         {:ok, %Payment{} = payment} <- fetch_payment(payment_id),
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

  def list_confirmed_payments() do
    Payment.list_confirmed()
    |> Repo.all()
    |> then(&{:ok, &1})
  end

  defp do_create_credit_card(params) do
    CreditCard.create(params)
    |> Repo.insert()
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

  def fetch_payment(payment_id) do
    Payment.fetch(payment_id)
    |> Repo.one()
    |> case do
      %Payment{} = payment ->
        {:ok, payment}

      nil ->
        {:error, {:resource_not_found, %{target: Payment, conditions: %{payment_id: payment_id}}}}
    end
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
               confirm_payment(
                 payment,
                 payment_info |> Map.from_struct() |> Map.put(:credit_card_id, credit_card.id)
               ) do
          {:ok, confirmed_payment}
        end

      {:error, reason} ->
        with {:ok, %Payment{} = failed_payment} <-
               fail_payment(payment, reason) do
          {:error, failed_payment}
        end
    end
  rescue
    e ->
      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      with {:ok, %Payment{} = failed_payment} <-
             fail_payment(payment, %{error: inspect(e)}) do
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
         credit_card_id: credit_card_id,
         confirmed_at: confirmed_at,
         provider: provider,
         provider_key: provider_key,
         item: item,
         payload: payload
       }) do
    payment
    |> Payment.confirm(%{
      credit_card_id: credit_card_id,
      confirmed_at: confirmed_at,
      provider: provider,
      provider_key: provider_key,
      item: item,
      payload: payload
    })
    |> Repo.update()
  end

  defp fail_payment(%Payment{} = payment, reason) do
    payment
    |> Payment.fail(%{
      failed_at: DateTime.utc_now(),
      payload: reason
    })
    |> Repo.update()
  end
end
