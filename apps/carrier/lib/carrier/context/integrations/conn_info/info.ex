defmodule Carrier.Integrations.ConnInfo.Info do
  import Ecto.Changeset, only: [apply_changes: 1]
  alias Carrier.Integrations.ConnInfo

  @callback changeset(struct :: struct(), attrs :: map()) :: %Ecto.Changeset{}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      use Ecto.Schema
      import Ecto.Changeset
    end
  end

  def get_changeset(source, info) do
    module = get_module(source)
    module.changeset(info)
  end

  def get_struct(source, info) do
    get_changeset(source, info)
    |> apply_changes()
  end

  def to_credentials(source, info) do
    get_struct(source, info)
    |> Map.from_struct()
  end

  def get_module(source) do
    case source do
      :postgres -> ConnInfo.Postgres
      :mysql -> ConnInfo.MySQL
      :bigquery -> ConnInfo.BigQuery
      :athena -> ConnInfo.Athena
      :slack -> ConnInfo.Slack
      :tableau -> ConnInfo.Tableau
    end
  end
end
