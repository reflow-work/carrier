defmodule Carrier.External.Aws do
  def create_client(%{
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        region: region
      }) do
    AWS.Client.create(access_key_id, secret_access_key, region)
    |> Map.put(:http_client, {__MODULE__.TeslaClient, []})
  end

  def create_internal_client() do
    create_client(%{
      access_key_id: get_access_key_id(),
      secret_access_key: get_secret_access_key(),
      region: get_default_region()
    })
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
