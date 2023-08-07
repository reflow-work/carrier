defmodule Carrier.Data.Source.Amplitude do
  @behaviour Carrier.Data.Source

  defmodule Dashboard do
    defstruct [:url]
  end

  ### behaviors

  @impl true
  def validate_conn(:amplitude, _credentials, _opts) do
    :ok
  end
end
