defmodule CarrierWeb.Components.DataSourceSelectorNew do
  use CarrierWeb, :live_component
  alias Carrier.Integrations.DataSource
  alias Carrier.Core.{Nillable}

  defp data_source_options(data_sources) do
    data_sources
    |> Enum.map(fn %DataSource{id: id, name: name} -> {name, id} end)
  end
end
