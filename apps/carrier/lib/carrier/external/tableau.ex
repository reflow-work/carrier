defmodule Carrier.External.Tableau do
  require Logger

  @api_version 3.18

  defmodule Pagination do
    defstruct [:page, :page_size, :total]

    def new(%{
          "pageNumber" => page_str,
          "pageSize" => page_size_str,
          "totalAvailable" => total_str
        }) do
      %__MODULE__{
        page: String.to_integer(page_str),
        page_size: String.to_integer(page_size_str),
        total: String.to_integer(total_str)
      }
    end
  end

  defmodule View do
    defstruct [:id, :name, :full_name]

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "Project"},
          "project" => %{"name" => project_name},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "#{project_name} / #{workbook_name} / #{name}"}
    end

    def new(%{
          "id" => id,
          "name" => name,
          "location" => %{"type" => "PersonalSpace"},
          "workbook" => %{"name" => workbook_name}
        }) do
      %__MODULE__{id: id, name: name, full_name: "Personal Space / #{workbook_name} / #{name}"}
    end
  end

  def signin(%{host: host, name: name, password: password, site: site}) do
    Tesla.post(client(host), "/auth/signin", %{
      "credentials" => %{
        "name" => name,
        "password" => password,
        "site" => %{
          "contentUrl" => site
        }
      }
    })
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
