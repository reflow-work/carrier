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
      {Tesla.Middleware.Timeout, timeout: :timer.minutes(1)}
    ])
  end
end
