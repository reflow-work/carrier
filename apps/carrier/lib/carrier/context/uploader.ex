defmodule Carrier.Uploader do
  require Logger
  alias Carrier.Const
  alias Carrier.Core.Crypto
  alias Carrier.External.Aws

  def upload(storage, org_id, binary, format) do
    %{region: region, bucket: bucket} = Const.get(storage)
    %{ext: ext, content_type: content_type} = format_info(format)

    key =
      "#{Crypto.obfuscate(org_id)}/#{Crypto.hash_to_url64(binary, :md5, padding: false)}.#{ext}"

    upload_url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"

    Aws.create_internal_client()
    |> Aws.S3.put_object(%{
      bucket: bucket,
      key: key,
      body: binary,
      content_type: content_type
    })
    |> case do
      {:ok, _, %{status_code: 200}} ->
        {:ok, upload_url}

      {:error, reason} ->
        Logger.error("Failed to upload: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp format_info(format) do
    case format do
      :png -> %{ext: "png", content_type: "image/png"}
      :pdf -> %{ext: "pdf", content_type: "application/pdf"}
    end
  end
end
