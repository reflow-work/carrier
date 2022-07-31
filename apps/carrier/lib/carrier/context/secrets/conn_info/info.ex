defmodule Carrier.Secrets.ConnInfo.Info do
  @callback changeset(struct :: struct(), attrs :: map()) :: %Ecto.Changeset{}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      use Ecto.Schema
      import Ecto.Changeset
    end
  end
end
