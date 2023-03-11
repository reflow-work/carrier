defmodule Carrier.Reports.DataSourceInfo do
  def get_changeset(%{source: source} = data_source_info) do
    module = get_module(source)
    module.changeset(data_source_info)
  end

  defp get_module(source) do
    case source do
      source when source in [:postgres, :mysql, :bigquery, :athena] -> __MODULE__.RDB
      :tableau -> __MODULE__.Tableau
    end
  end
end
