defmodule Carrier.Data.Source.Tableau do
  alias Carrier.External.Tableau, as: TableauAPI

  def list_views(%{host: host, id: id, password: password, site: site}) do
    with {:ok, %{token: token, site_id: site_id}} <- TableauAPI.signin(host, id, password, site),
         {:ok, views} <- do_list_views(%{host: host, site_id: site_id, token: token}) do
      {:ok, views}
    end
  end

  defp do_list_views(%{host: host, site_id: site_id, token: token}) do
    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok, %{views: views, pagination: %{page: page, page_size: page_size, total: total}}} =
          TableauAPI.query_views_for_site(host, site_id, page, token)

        last_page = div(total, page_size) + 1

        case last_page == page do
          true -> {views, nil}
          false -> {views, page + 1}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
  end
end
