defmodule Carrier.External.Aws.TeslaClient do
  @behaviour AWS.HTTPClient

  @impl true
  @spec request(
          method :: atom(),
          url :: binary(),
          body :: iodata(),
          headers :: list(),
          options :: keyword()
        ) ::
          {:ok, %{status_code: integer(), headers: [{binary(), binary()}], body: binary()}}
          | {:error, term()}
  def request(method, url, body, headers, options) do
    Tesla.request(client(),
      method: method,
      url: url,
      body: body,
      headers: headers,
      opts: options
    )
    |> case do
      {:ok, %Tesla.Env{status: status, headers: headers, body: body}} ->
        {:ok, %{status_code: status, headers: headers, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp client() do
    Tesla.client([
      {Tesla.Middleware.Retry,
       delay: 500,
       max_retries: 3,
       max_delay: 4_000,
       should_retry: fn
         {:ok, %{status: 200}} -> false
         _ -> true
       end},
      {Tesla.Middleware.Timeout, timeout: :timer.minutes(3)}
    ])
  end
end
