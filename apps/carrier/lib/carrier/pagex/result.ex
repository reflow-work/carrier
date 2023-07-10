defmodule Carrier.Pagex.Result do
  @enforce_keys [:entries, :meta]
  defstruct [:entries, :meta]
end
