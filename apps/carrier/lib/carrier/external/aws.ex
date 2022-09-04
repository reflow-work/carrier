defmodule Carrier.External.Aws do
  import AWS

  def save_chart_img(%{columns: columns, data: data, orgId: orgId, reportId: reportId}) do
    create_client()
    |> AWS.Lambda.invoke("createChartImage", %{
      columns: columns,
      data: data,
      orgId: orgId,
      reportId: reportId
    })
  end

  defp create_client() do
    AWS.Client.create(get_access_key_id(), get_secret_access_key(), get_default_region())
    |> Map.put(:http_client, {Carrier.External.Aws.TeslaClient, []})
  end

  defp get_access_key_id() do
    Application.get_env(:aws, :access_key_id)
  end

  defp get_secret_access_key() do
    Application.get_env(:aws, :secret_access_key)
  end

  defp get_default_region() do
    Application.get_env(:aws, :default_region)
  end
end
