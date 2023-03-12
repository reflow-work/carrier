defmodule Carrier.External.Aws.S3 do
  def put_object(client, %{bucket: bucket, key: key, body: body, content_type: content_type}) do
    AWS.S3.put_object(
      client,
      bucket,
      key,
      %{"Body" => body, "ContentType" => content_type}
    )
  end
end
