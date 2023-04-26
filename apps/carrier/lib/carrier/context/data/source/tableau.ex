defmodule Carrier.Data.Source.Tableau do
  alias Carrier.External.Tableau, as: TableauAPI

  def list_views(%{host: host} = conn_info) do
    with {:ok, %{token: token, site_id: site_id}} <- signin(conn_info),
         {:ok, views} <- do_list_views(%{host: host, site_id: site_id, token: token}) do
      {:ok, views}
    end
  end

  def get_view_image_binary(view_id, %{host: host} = conn_info) do
    with {:ok, %{token: token, site_id: site_id}} <- signin(conn_info),
         {:ok, view_image_binary} <-
           TableauAPI.query_view_image(%{
             host: host,
             site_id: site_id,
             view_id: view_id,
             token: token
           }) do
      {:ok, view_image_binary}
    end
  end

  defp signin(%{host: host, id: id, password: password, site: site}) do
    TableauAPI.signin(%{host: host, name: id, password: password, site: site})
  end

  defp do_list_views(%{host: host, site_id: site_id, token: token}) do
    Stream.unfold(1, fn
      nil ->
        nil

      page ->
        {:ok, %{views: views, pagination: %{page: page, page_size: page_size, total: total}}} =
          TableauAPI.query_views_for_site(%{
            host: host,
            site_id: site_id,
            page: page,
            token: token
          })

        last_page = div(total, page_size) + 1

        case last_page == page do
          true -> {views, nil}
          false -> {views, page + 1}
        end
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> then(&{:ok, &1})
  end
end
