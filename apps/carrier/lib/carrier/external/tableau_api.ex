defmodule Carrier.External.TableauAPI do
  require Logger
  alias Carrier.Data.Source.Tableau.{Pagination, View}


  @api_version 3.18

  def signin(%{host: host, name: name, password: password, site: site}) do
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

  def signin(%{host: host, pat_name: pat_name, pat_secret: pat_secret, site: site}) do
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
        {:ok, %{token: token, site_id: site_id}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def query_views_for_site(%{host: host, site_id: site_id, page: page, token: token}) do
    Tesla.get(client(host, token), "/sites/#{site_id}/views",
      query: [
        {"pageNumber", page},
        {"pageSize", 1000},
        {"fields", "_default_,project.name,workbook.name"}
      ]
    )
    |> handle_response()
    |> case do
      {:ok, %{"views" => %{"view" => views}, "pagination" => raw_pagination}} ->
        {:ok,
         %{views: views |> Enum.map(&View.new/1), pagination: Pagination.new(raw_pagination)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def query_view_image(%{host: host, site_id: site_id, view_id: view_id, token: token}) do
    Tesla.get(client(host, token), "/sites/#{site_id}/views/#{view_id}/image")
    |> handle_response()
  end

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Tesla.Env{body: %{"error" => %{"detail" => detail} = error}}}) do
    Logger.error("Tableau API error: #{inspect(error)}")

    {:error, detail}
  end

  defp handle_response({:error, reason}) do
    Logger.error("Tableau API error: #{inspect(reason)}")

    {:error, reason}
  end

  defp client(host, token \\ nil) do
    middlewares =
      [
        {Tesla.Middleware.BaseUrl, "#{host}/api/#{@api_version}"},
        {Tesla.Middleware.Headers, [{"Accept", "application/json"}]},
        Tesla.Middleware.JSON
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
