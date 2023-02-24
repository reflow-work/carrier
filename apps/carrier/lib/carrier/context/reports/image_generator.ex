defmodule Carrier.Reports.ImageGenerator do
  require Logger
  alias Carrier.External.Aws

  def gen_chart_images(%{org_id: org_id, report_id: report_id, data: data}) do
    Aws.create_internal_client()
    |> Aws.Lambda.invoke("createChartImage", %{
      "orgId" => org_id,
      "reportId" => report_id,
      "data" => data
    })
    |> case do
      {:ok, %{"body" => %{"imgUrls" => image_urls}}, _full_resp} ->
        {:ok, %{image_urls: image_urls}}

      {:error, reason} ->
        Logger.error("Failed to generate chart images: #{inspect(reason)}")

        {:error, reason}
    end
  end
end
