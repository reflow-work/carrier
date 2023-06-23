defmodule Carrier.Integrations.ConnValidator do
  alias Carrier.Integrations.ConnInfo
  alias Carrier.Data

  def validate(source, info, type, opts \\ []) do
    credentials = ConnInfo.Info.to_credentials(source, info)

    Data.validate_conn(source, credentials, type, opts)
  end
end
