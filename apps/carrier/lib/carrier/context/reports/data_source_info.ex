defmodule Carrier.Reports.DataSourceInfo do
  import Ecto.Changeset, only: [apply_changes: 1]

  def get_changeset(%{source: source} = data_source_info) do
    module = get_module(source)
    module.changeset(data_source_info)
  end

  def get_changeset(%{"source" => source} = data_source_info) do
    module = get_module(source)
    module.changeset(data_source_info)
  end

  def get_struct(data_source_info) do
    get_changeset(data_source_info)
    |> apply_changes()
  end

  defp get_module(source) do
    case source do
      source when source in [:postgres, :mysql, :bigquery, :athena] -> __MODULE__.RDB
      source when source in ["postgres", "mysql", "bigquery", "athena"] -> __MODULE__.RDB
      :tableau -> __MODULE__.Tableau
      "tableau" -> __MODULE__.Tableau
      :redash -> __MODULE__.Redash
      "redash" -> __MODULE__.Redash
    end
  end
end
