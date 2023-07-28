defmodule Carrier.External.RedashAPI do
  require Logger
  alias Carrier.Data.Source.Redash.{Pagination, Dashboard}
  alias Carrier.Core.Browser

  def list_dashboards(page, %{host: host, api_key: api_key}) do
    query = [
      {"page", page},
      {"page_size", 250},
      {"api_key", api_key}
    ]

    Tesla.get(client(host), "/api/dashboards", query: query)
    |> handle_response()
    |> case do
      {:ok, %{"results" => results} = body} ->
        {:ok,
         %{dashboards: results |> Enum.map(&Dashboard.new/1), pagination: Pagination.new(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_dashboard(id, %{host: host, api_key: api_key}) do
    Tesla.get(client(host), "/api/dashboards/#{id}", query: %{api_key: api_key})
    |> handle_response()
    |> case do
      {:ok, body} ->
        {:ok, Dashboard.new(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_dashboard_screenshot(dashboard_url) do
    Browser.screenshot(dashboard_url)
  end

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Tesla.Env{body: %{"message" => message}}}) do
    Logger.error("Redash API error: #{inspect(message)}")

    {:error, message}
  end

  defp handle_response({:error, reason}) do
    Logger.error("Redash API error: #{inspect(reason)}")

    {:error, reason}
  end

  defp client(host) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, "#{host}"},
      # {Tesla.Middleware.Headers, [{"Accept", "application/json"}]},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry,
       delay: 500,
       max_retries: 3,
       max_delay: 4_000,
       should_retry: fn
         {:ok, %{status: 200}} -> false
         _ -> true
       end},
      {Tesla.Middleware.Timeout, timeout: :timer.minutes(1)}
    ]

    Tesla.client(middlewares)
  end
end
