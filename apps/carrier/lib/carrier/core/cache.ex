defmodule Carrier.Core.Cache do
  defmacro __using__([]) do
    quote do
      use Nebulex.Caching
      alias unquote(__MODULE__)
    end
  end

  defmodule Local do
    use Nebulex.Cache,
      otp_app: :carrier,
      adapter: Nebulex.Adapters.Local
  end

  def ttl(ttl) do
    case Application.get_env(:carrier, __MODULE__)[:force_ttl] do
      nil -> ttl
      force_ttl -> force_ttl
    end
  end
end
