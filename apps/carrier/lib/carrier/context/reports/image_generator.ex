defmodule Carrier.Reports.ImageGenerator do
  require Logger
  alias Carrier.Core.Crypto
  alias Carrier.External.Aws

  def gen_chart_images(%{org_id: org_id, report_id: report_id, data: data}) do
    encoded_org_id = Crypto.obfuscate(org_id)

    # TODO: don't take "preview" as report_id
    encoded_report_id =
      case is_integer(report_id) do
        true -> Crypto.obfuscate(report_id)
        _ -> report_id
      end

    Aws.create_internal_client()
    |> Aws.Lambda.invoke("createChartImage", %{
      "orgId" => encoded_org_id,
      "reportId" => encoded_report_id,
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

  def upload_chart_image(%{org_id: org_id, report_id: report_id, binary: binary}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    bucket = "carrier-chart-img"
    region = "ap-northeast-2"
    encoded_org_id = Crypto.obfuscate(org_id)
    encoded_report_id = Crypto.obfuscate(report_id)
    key = "#{encoded_org_id}/#{encoded_report_id}/#{timestamp}.png"
    url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"

    Aws.create_internal_client()
    |> Aws.S3.put_object(%{
      bucket: bucket,
      key: key,
      body: binary,
      content_type: "image/png"
    })
    |> case do
      {:ok, _, %{status_code: 200}} ->
        {:ok, url}

      {:error, reason} ->
        Logger.error("Failed to upload chart image: #{inspect(reason)}")

        {:error, reason}
    end
  end
end
