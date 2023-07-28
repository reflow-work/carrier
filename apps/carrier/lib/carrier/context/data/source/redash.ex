defmodule Carrier.Data.Source.Redash do
  @behaviour Carrier.Data.Source


  ### behaviors

  @impl true
  def validate_conn(:redash, _credentials, _opts) do
    :ok
  end
end
