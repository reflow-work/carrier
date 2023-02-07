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

  def default_matcher({:ok, _}), do: true
  def default_matcher(_), do: false
end
