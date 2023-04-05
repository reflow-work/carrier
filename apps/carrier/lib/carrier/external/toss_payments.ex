defmodule Carrier.External.TossPayments do
  require Logger

  def issue_billing_auth(auth_key, customer_key) do
    body = %{
      "authKey" => auth_key,
      "customerKey" => customer_key
    }

    Tesla.post(client(), "/v1/billing/authorizations/issue", body)
    |> handle_response()
    |> case do
      {:ok, %{"billingKey" => billing_key, "customerKey" => customer_key}} ->
        {:ok, %{billing_key: billing_key, customer_key: customer_key}}

      {:error, reason} ->
        Logger.error("Failed to issue billing auth: #{customer_key}, #{inspect(reason)}")

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
         {:ok, %{status: 200}} -> false
         _ -> true
       end},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: :timer.seconds(10)}
    ])
  end

  defp base_url() do
    Application.get_env(:carrier, :toss_payments)[:base_url]
  end

  defp secret_key() do
    Application.get_env(:carrier, :toss_payments)[:secret_key]
  end
end
