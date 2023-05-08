defmodule Carrier.Data do
  defmacro __using__([]) do
    quote do
      use unquote(__MODULE__).{Source, Target}
    end
  end
end
