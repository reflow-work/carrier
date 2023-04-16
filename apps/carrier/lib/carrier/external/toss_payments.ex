defmodule Carrier.External.TossPayments do
  require Logger
  alias Carrier.External.Model.{CreditCardInfo, PaymentInfo}

  def issue_billing_auth(auth_key, customer_key) do
    body = %{
      "authKey" => auth_key,
      "customerKey" => customer_key
    }

    Tesla.post(client(), "/v1/billing/authorizations/issue", body)
    |> handle_response()
    |> case do
      {:ok,
       %{
         "billingKey" => billing_key,
         "customerKey" => customer_key,
         "cardCompany" => card_company,
         "cardNumber" => card_number
       }} ->
        {:ok,
         %CreditCardInfo{
           provider: :toss_payments,
           billing_key: billing_key,
           customer_key: customer_key,
           card_company: card_company,
           card_number: card_number
         }}

      {:error, reason} ->
        Logger.error("Failed to issue billing auth: #{customer_key}, #{inspect(reason)}")

        {:error, reason}
    end
  end

  # order_id should be unique and its length should be >= 6
  def bill(%{
        billing_key: billing_key,
        amount: %Decimal{} = amount,
        customer_key: customer_key,
        order_id: order_id,
        order_name: order_name,
        customer_email: customer_email,
        customer_name: customer_name
      }) do
    body = %{
      "amount" => amount |> Decimal.to_integer(),
      "customerKey" => customer_key,
      "orderId" => order_id,
      "orderName" => order_name,
      "customerEmail" => customer_email,
      "customerName" => customer_name
    }

    Tesla.post(client(), "/v1/billing/#{billing_key}", body)
    |> handle_response()
    |> case do
      {:ok, %{"orderId" => order_id, "approvedAt" => approved_at_str} = body} ->
        {:ok, approved_at, _offset} = DateTime.from_iso8601(approved_at_str)

        {:ok,
         %PaymentInfo{
           provider: :toss_payments,
           provider_key: order_id,
           confirmed_at: approved_at,
           payload: body
         }}

      {:error, reason} ->
        Logger.error("Failed to bill: #{order_id}, #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp handle_response(response) do
    case response do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{body: reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, base_url()},
      {Tesla.Middleware.BasicAuth, username: secret_key(), password: ""},
      {Tesla.Middleware.Retry,
       delay: 500,
       max_retries: 3,
       max_delay: 4_000,
       should_retry: fn
         {:ok, %{status: status}} when status >= 200 and status < 500 -> false
         _ -> true
       end},
      Tesla.Middleware.JSON,
      # https://docs.tosspayments.com/reference#%EC%B9%B4%EB%93%9C-%EC%9E%90%EB%8F%99-%EA%B2%B0%EC%A0%9C-%EC%8A%B9%EC%9D%B8
      {Tesla.Middleware.Timeout, timeout: :timer.seconds(30)}
    ])
  end

  defp base_url() do
    Application.get_env(:carrier, :toss_payments)[:base_url]
  end

  defp secret_key() do
    Application.get_env(:carrier, :toss_payments)[:secret_key]
  end
end
