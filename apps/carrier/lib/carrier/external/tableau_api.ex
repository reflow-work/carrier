defmodule Carrier.External.TableauAPI do
  require Logger
  alias Carrier.Data.Source.Tableau.{Pagination, View}

  @api_version 3.18

  def signin(%{type: :user, host: host, name: name, password: password, site: site}) do
    body = %{
      "credentials" => %{
        "name" => name,
        "password" => password,
        "site" => %{
          "contentUrl" => site
        }
      }
    }

    do_signin(host, body)
  end

  def signin(%{type: :pat, host: host, pat_name: pat_name, pat_secret: pat_secret, site: site}) do
    body = %{
      "credentials" => %{
        "personalAccessTokenName" => pat_name,
        "personalAccessTokenSecret" => pat_secret,
        "site" => %{
          "contentUrl" => site
        }
      }
    }

    do_signin(host, body)
  end

  defp do_signin(host, body) do
    Tesla.post(client(host), "/auth/signin", body)
    |> handle_response()
    |> case do
      {:ok, %{"credentials" => %{"token" => token, "site" => %{"id" => site_id}}}} ->
        expired_at = DateTime.utc_now() |> DateTime.add(1, :hour)

        {:ok, %{host: host, token: token, site_id: site_id, expired_at: expired_at}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_view(%{view_id: view_id, host: host, site_id: site_id, token: token}) do
    query = [
      {"fields", "_default_,project.name,workbook.name,workbook.contentUrl"}
    ]

    Tesla.get(client(host, token), "/sites/#{site_id}/views/#{view_id}", query: query)
    |> handle_response()
    |> case do
      {:ok, %{"view" => view}} ->
        {:ok, View.new(view)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def query_views_for_site(%{host: host, site_id: site_id, page: page, token: token}) do
    query = [
      {"pageNumber", page},
      {"pageSize", 1000},
      {"fields", "_default_,project.name,workbook.name,workbook.contentUrl"}
    ]

    Tesla.get(client(host, token), "/sites/#{site_id}/views", query: query)
    |> handle_response()
    |> case do
      {:ok, %{"views" => %{"view" => views}, "pagination" => raw_pagination}} ->
        {:ok,
         %{views: views |> Enum.map(&View.new/1), pagination: Pagination.new(raw_pagination)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def query_view_preview_image(%{
        host: host,
        site_id: site_id,
        workbook_id: workbook_id,
        view_id: view_id,
        token: token
      }) do
    Tesla.get(
      client(host, token),
      "/sites/#{site_id}/workbooks/#{workbook_id}/views/#{view_id}/previewImage"
    )
    |> handle_response()
  end

  def query_view_image(%{host: host, site_id: site_id, view_id: view_id, token: token}) do
    query = [
      {"maxAge", 1}
    ]

    Tesla.get(client(host, token), "/sites/#{site_id}/views/#{view_id}/image", query: query)
    |> handle_response()
  end

  def query_view_pdf(%{host: host, site_id: site_id, view_id: view_id, token: token}) do
    query = [
      {"vizWidth", 2500}
    ]

    Tesla.get(client(host, token), "/sites/#{site_id}/views/#{view_id}/pdf", query: query)
    |> handle_response()
  end

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Tesla.Env{body: %{"error" => error}}}) do
    Logger.error("Tableau API error: #{inspect(error)}")

    {:error, translate_error(error)}
  end

  defp handle_response({:error, reason}) do
    Logger.error("Tableau API error: #{inspect(reason)}")

    {:error, reason}
  end

  defp translate_error(%{"code" => code, "detail" => detail}) do
    case code do
      "403004" -> {:tableau_api_forbidden, detail}
      "401001" -> {:tableau_api_invalid_access_token, detail}
      "401002" -> {:tableau_api_invalid_auth_credentials, detail}
      _ -> {:tableau_api_unknown_error, detail}
    end
  end

  defp translate_error(_) do
    {:error, {:tableau_api_unknown_error, "Unknown error"}}
  end

  defp client(host, token \\ nil) do
    middlewares =
      [
        {Tesla.Middleware.BaseUrl, "#{host}/api/#{@api_version}"},
        {Tesla.Middleware.Headers, [{"Accept", "application/json"}]},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Retry,
         delay: 500,
         max_retries: 3,
         max_delay: 4_000,
         should_retry: fn
           {:ok, %{status: 200}} -> false
           _ -> true
         end},
        {Tesla.Middleware.Timeout, timeout: :timer.minutes(10)}
      ]
      |> then(fn middlewares ->
        case token do
          nil -> middlewares
          token -> middlewares ++ [{Tesla.Middleware.Headers, [{"X-Tableau-Auth", token}]}]
        end
      end)

    Tesla.client(middlewares)
  end
end
