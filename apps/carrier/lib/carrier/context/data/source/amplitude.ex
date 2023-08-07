defmodule Carrier.Data.Source.Amplitude do
  @behaviour Carrier.Data.Source

  ### behaviors

  @impl true
  def validate_conn(:amplitude, _credentials, _opts) do
    :ok
  end
end
