defmodule Carrier.Secrets.ConnInfo.Info do
  alias Carrier.Secrets.ConnInfo

  @callback changeset(struct :: struct(), attrs :: map()) :: %Ecto.Changeset{}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      use Ecto.Schema
      import Ecto.Changeset
    end
  end

  def get_module_from_source(source) do
    case source do
      :postgres -> ConnInfo.Postgres
      :mysql -> ConnInfo.MySQL
    end
  end
end
