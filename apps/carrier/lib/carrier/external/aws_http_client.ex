defmodule Carrier.External.Aws.HTTPClient do
  require Logger

  @callback request(
              method :: atom(),
              url :: binary(),
              body :: iodata(),
              headers :: list(),
              options :: keyword()
            ) ::
              {:ok, %{status_code: integer(), headers: [{binary(), binary()}], body: binary()}}
              | {:error, term()}

  @hackney_pool_name :aws_pool

  def request(method, url, body, headers, options) do
    ensure_hackney_running!()

    options = 
      [:with_body | options] 
      |> Keyword.put_new(:pool, @hackney_pool_name)
      |> Keyword.put_new(:recv_timeout, 300000)

    case :hackney.request(method, url, headers, body, options) do
      {:ok, status_code, response_headers, body} ->
        {:ok, %{status_code: status_code, headers: response_headers, body: body}}

      {:ok, status_code, response_headers} ->
        {:ok, %{status_code: status_code, headers: response_headers, body: ""}}

      {:error, _error} = error ->
        error
    end
  end

  defp ensure_hackney_running!() do
    unless Code.ensure_loaded?(:hackney) do
      Logger.error("""
      Could not find hackney dependency.

      Please add :hackney to your dependencies:

          {:hackney, "~> 1.16"}

      Or provide your own #{__MODULE__} implementation:

          %AWS.Client{http_client: {MyCustomHTTPClient, []}}
      """)

      raise "missing hackney dependency"
    end

    {:ok, _apps} = Application.ensure_all_started(:hackney)
  end
end
