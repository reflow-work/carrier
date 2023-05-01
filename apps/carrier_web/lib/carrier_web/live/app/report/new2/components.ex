defmodule CarrierWeb.App.ReportLive.New2.Components do
  use CarrierWeb, :component
  use Carrier.Secrets
  alias Carrier.Core.Nillable

  embed_templates "*"

  attr :data_sources, :list, required: true
  attr :selected_data_source, :any, required: true
  attr :onselect, :any, required: true

  def data_source_selector(assigns)

  defp data_source_options(data_sources) do
    data_sources
    |> Enum.map(fn %DataSource{id: id, name: name} -> {name, id} end)
  end

  attr :data_source, :any, required: true

  def data_transformer(assigns) do
    case assigns.data_source do
      nil ->
        empty_data_transformer(assigns)

      %DataSource{source: :tableau} ->
        ~H"""
        <.live_component
          module={CarrierWeb.App.ReportLive.New2.TableauDataTransformer}
          id="tableau_data_transformer"
          data_source={@data_source}
        />
        """

      _ ->
        ~H"""
        Not implemented
        """
    end
  end
end
